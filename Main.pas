unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.Menus, Vcl.ComCtrls, Vcl.StdCtrls, System.UITypes, Vcl.Themes,
  Vcl.GraphUtil, System.StrUtils, Vcl.Clipbrd, Vcl.ExtCtrls, Math,
  SynEdit, SynEditHighlighter, SynEditCodeFolding, SynHighlighterPas,
  SynEditTypes, SynEditMiscClasses, SynEditKeyCmds, SynEditTextBuffer,
  SynEditMiscProcs, SynEditScrollBars, Registry;

type
  TForm1 = class(TForm)
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    MainMenu1: TMainMenu;
    New: TMenuItem;
    Open: TMenuItem;
    Save: TMenuItem;
    SaveAs: TMenuItem;
    Exit1: TMenuItem;
    Edit: TMenuItem;
    Cut: TMenuItem;
    Copy: TMenuItem;
    Paste: TMenuItem;
    Delete: TMenuItem;
    Format: TMenuItem;
    FontSize: TMenuItem;
    FontColor: TMenuItem;
    CheckSyntaxBtn: TButton;
    StatusBar1: TStatusBar;
    FontDialog1: TFontDialog;
    ColorDialog1: TColorDialog;
    SynPasSyn1: TSynPasSyn;
    SynEdit1: TSynEdit;
    StatusBarPopupMenu: TPopupMenu;
    procedure OpenClick(Sender: TObject);
    procedure NewClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure SaveAsClick(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure CutClick(Sender: TObject);
    procedure CopyClick(Sender: TObject);
    procedure PasteClick(Sender: TObject);
    procedure DeleteClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CheckSyntaxBtnClick(Sender: TObject);
    procedure FontColorClick(Sender: TObject);
    procedure FontSizeClick(Sender: TObject);
    procedure SynEdit1Change(Sender: TObject);
    procedure SynEdit1Paint(Sender: TObject);
    procedure SynEdit1SpecialLineColors(Sender: TObject; Line: Integer;
      var Special: Boolean; var FG, BG: TColor);
    procedure CopyStatusText1Click(Sender: TObject);
  private
    FFileName: string;
    FErrorLine: Integer;
    procedure SetFileName(const Value: string);
    procedure CheckSyntax;
    procedure CheckParenthesesBalance;
    procedure CheckSemicolonUsage;
    procedure CheckIfThenBalance;
    procedure CheckProcedureFunctionDeclarations;
    procedure CheckVariableDeclarations;
    procedure CheckTypeDeclarations;
    procedure CheckConstantDeclarations;
    procedure ShowError(const ErrorMsg: string; LineNumber: Integer = -1);
    function CountOccurrences(const SubStr, Str: string): Integer;
    procedure ConfigureSyntaxColors;
    property FileName: string read FFileName write SetFileName;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.SetFileName(const Value: string);
begin
  FFileName := Value;
  Caption := 'Delphi Editor - ' + ExtractFileName(FFileName);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Reg: TRegistry;
  LastDir: string;
begin
  OpenDialog1.Filter :=
    'Delphi files (*.dpr;*.dpk)|*.dpr;*.dpk|' +
    'Pascal files (*.pas)|*.pas|' +
    'Form files (*.dfm)|*.dfm|' +
    'Resource files (*.res)|*.res|' +
    'Text files (*.txt)|*.txt|' +
    'All files (*.*)|*.*';
  SaveDialog1.Filter := OpenDialog1.Filter;
  
  // Загружаем последнюю папку из реестра
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('\Software\DelphiEditor', True) then
    begin
      if Reg.ValueExists('LastDirectory') then
        LastDir := Reg.ReadString('LastDirectory')
      else
        LastDir := ExtractFilePath(Application.ExeName);
      Reg.CloseKey;
    end
    else
      LastDir := ExtractFilePath(Application.ExeName);
  finally
    Reg.Free;
  end;
  
  OpenDialog1.InitialDir := LastDir;
  SaveDialog1.InitialDir := LastDir;

  // Initialize status bar panels
  StatusBar1.Panels.Clear; // Очищаем существующие панели
  with StatusBar1.Panels do
  begin
    Add;
    Add;
    Add;
    
    // Настраиваем панели
    StatusBar1.SimplePanel := False;
    
    // Первая панель - количество символов
    Items[0].Style := psText;
    Items[0].Bevel := pbLowered;
    Items[0].Alignment := taLeftJustify;
    Items[0].Width := 150; // Увеличиваем ширину
    
    // Вторая панель - количество строк
    Items[1].Style := psText;
    Items[1].Bevel := pbLowered;
    Items[1].Alignment := taLeftJustify;
    Items[1].Width := 150; // Увеличиваем ширину
    
    // Третья панель - сообщения об ошибках
    Items[2].Style := psText;
    Items[2].Bevel := pbLowered;
    Items[2].Alignment := taLeftJustify;
    Items[2].Width := StatusBar1.Width - 300; // Учитываем увеличенную ширину первых двух панелей
  end;

  // Привязываем контекстное меню к статусбару
  StatusBar1.PopupMenu := StatusBarPopupMenu;

  SynEdit1.Font.Name := 'Consolas';
  SynEdit1.Font.Size := 10;
  SynEdit1.Highlighter := SynPasSyn1;
  SynEdit1.Gutter.ShowLineNumbers := True;
  SynEdit1.Gutter.Font := SynEdit1.Font;
  
  // Настраиваем начальные цвета подсветки
  ConfigureSyntaxColors;

  FileName := '';
  FErrorLine := -1;
  
  // Инициализируем информацию о количестве строк и символов
  StatusBar1.Panels[0].Text := 'Символов: 0';
  StatusBar1.Panels[1].Text := 'Строк: 0';
  
  // Загружаем последний открытый файл из реестра, если нет параметров командной строки
  if ParamCount = 0 then // Проверяем наличие параметров командной строки
  begin
    Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKey('\Software\DelphiEditor', False) then // Открываем ключ только для чтения
      begin
        // Сначала проверяем, был ли пустой файл
        if Reg.ValueExists('WasEmpty') and Reg.ReadBool('WasEmpty') then
        begin
          // Если был пустой файл, очищаем редактор
          FileName := '';
          SynEdit1.Clear;
          Caption := 'Delphi Editor';
          StatusBar1.Panels[2].Text := '';
          
          // Обновляем информацию о количестве строк и символов
          StatusBar1.Panels[0].Text := 'Символов: 0';
          StatusBar1.Panels[1].Text := 'Строк: 0';
        end
        // Если не было пустого файла, проверяем наличие последнего файла
        else if Reg.ValueExists('LastFile') then
        begin
          FFileName := Reg.ReadString('LastFile');
          if FileExists(FFileName) then // Проверяем, существует ли файл
          begin
            SynEdit1.Lines.LoadFromFile(FFileName);
            Caption := 'Delphi Editor - ' + ExtractFileName(FFileName);
            SynEdit1.Modified := False;
            StatusBar1.Panels[2].Text := '';
            
            // Обновляем информацию о количестве строк и символов
            StatusBar1.Panels[0].Text := 'Символов: ' + IntToStr(Length(SynEdit1.Text));
            StatusBar1.Panels[1].Text := 'Строк: ' + IntToStr(SynEdit1.Lines.Count);
          end
          else
          begin
            // Если файл не найден, очищаем запись в реестре
            Reg.DeleteValue('LastFile');
            FileName := ''; // Сбрасываем имя файла в редакторе
            SynEdit1.Clear; // Очищаем редактор
            Caption := 'Delphi Editor';
            StatusBar1.Panels[2].Text := 'Последний файл не найден.';
          end;
        end
        else
        begin
          // Если нет ни пустого файла, ни последнего файла, очищаем редактор
          FileName := '';
          SynEdit1.Clear;
          Caption := 'Delphi Editor';
        end;
        Reg.CloseKey;
      end
      else
      begin
        // Если ключа реестра нет, очищаем редактор
        FileName := '';
        SynEdit1.Clear;
        Caption := 'Delphi Editor';
      end;
    finally
      Reg.Free;
    end;
  end
  else // Если есть параметры командной строки (открыто через "Открыть с помощью")
  begin
    FFileName := ParamStr(1); // Первый параметр - это путь к файлу
    if FileExists(FFileName) then
    begin
      SynEdit1.Lines.LoadFromFile(FFileName);
      Caption := 'Delphi Editor - ' + ExtractFileName(FFileName);
      SynEdit1.Modified := False;
      StatusBar1.Panels[2].Text := '';
      
      // Обновляем информацию о количестве строк и символов
      StatusBar1.Panels[0].Text := 'Символов: ' + IntToStr(Length(SynEdit1.Text));
      StatusBar1.Panels[1].Text := 'Строк: ' + IntToStr(SynEdit1.Lines.Count);
      
      // Сохраняем путь к открытому через "Открыть с помощью" файлу в реестр
      Reg := TRegistry.Create;
      try
        Reg.RootKey := HKEY_CURRENT_USER;
        if Reg.OpenKey('\Software\DelphiEditor', True) then
        begin
          Reg.WriteString('LastFile', FFileName);
          Reg.WriteBool('WasEmpty', False);
          Reg.CloseKey();
        end;
      finally
        Reg.Free();
      end;
    end
    else
    begin
      // Если файл, указанный в командной строке, не найден
      FileName := ''; // Сбрасываем имя файла в редакторе
      SynEdit1.Clear; // Очищаем редактор
      Caption := 'Delphi Editor';
      StatusBar1.Panels[2].Text := 'Файл из командной строки не найден.';
    end;
  end;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  Reg: TRegistry;
begin
  if SynEdit1.Modified then
  begin
    case MessageDlg('Документ изменен. Сохранить изменения?', mtConfirmation,
      [mbYes, mbNo, mbCancel], 0) of
      mrYes:
        SaveClick(Sender);
      mrCancel:
        CanClose := False;
    end;
  end;

  // Сохраняем состояние пустого файла
  if CanClose then
  begin
    Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKey('\Software\DelphiEditor', True) then
      begin
        if FileName = '' then
          Reg.WriteBool('WasEmpty', True)
        else
          Reg.WriteBool('WasEmpty', False);
        Reg.CloseKey;
      end;
    finally
      Reg.Free;
    end;
  end;
end;

procedure TForm1.OpenClick(Sender: TObject);
var
  Reg: TRegistry;
  LastDir: string;
  CanContinue: Boolean; // Переменная для отслеживания, можно ли продолжить открытие файла
begin
  CanContinue := True; // По умолчанию разрешаем продолжить
  
  if SynEdit1.Modified then // Проверяем, были ли изменения в текущем файле
  begin
    case MessageDlg('Документ изменен. Сохранить изменения?', mtConfirmation,
      [mbYes, mbNo, mbCancel], 0) of
      mrYes:
        SaveClick(Sender); // Сохраняем изменения
      mrCancel:
        CanContinue := False; // Отменяем открытие нового файла
    end;
  end;
  
  if CanContinue then // Если разрешено продолжить
  begin
    if OpenDialog1.Execute then
    begin
      SynEdit1.Lines.LoadFromFile(OpenDialog1.FileName);
      FileName := OpenDialog1.FileName;
      SynEdit1.Modified := False;
      StatusBar1.Panels[2].Text := '';
      
      // Обновляем информацию о количестве строк и символов
      StatusBar1.Panels[0].Text := 'Символов: ' + IntToStr(Length(SynEdit1.Text));
      StatusBar1.Panels[1].Text := 'Строк: ' + IntToStr(SynEdit1.Lines.Count);
      
      // Сбрасываем ошибку и подсветку при открытии нового файла
      if FErrorLine >= 0 then
      begin
        SynEdit1.InvalidateLine(FErrorLine + 1); // Перерисовываем предыдущую строку с ошибкой
        FErrorLine := -1;
      end;
      
      // Сохраняем папку в реестр
      LastDir := ExtractFilePath(OpenDialog1.FileName);
      Reg := TRegistry.Create;
      try
        Reg.RootKey := HKEY_CURRENT_USER;
        if Reg.OpenKey('\Software\DelphiEditor', True) then
        begin
          Reg.WriteString('LastDirectory', LastDir);
          Reg.CloseKey;
        end;
      finally
        Reg.Free;
      end;
      
      // Сохраняем путь к открытому файлу в реестр
      Reg := TRegistry.Create;
      try
        Reg.RootKey := HKEY_CURRENT_USER;
        if Reg.OpenKey('\Software\DelphiEditor', True) then
        begin
          Reg.WriteString('LastFile', OpenDialog1.FileName);
          Reg.CloseKey();
        end;
      finally
        Reg.Free;
      end;
    end;
  end;
end;

procedure TForm1.SaveClick(Sender: TObject);
begin
  if FileName = '' then
    SaveAsClick(Sender)
  else
  begin
    SynEdit1.Lines.SaveToFile(FileName);
    SynEdit1.Modified := False;
  end;
end;

procedure TForm1.SaveAsClick(Sender: TObject);
var
  Reg: TRegistry;
  LastDir: string;
begin
  if SaveDialog1.Execute then
  begin
    SynEdit1.Lines.SaveToFile(SaveDialog1.FileName);
    FileName := SaveDialog1.FileName;
    SynEdit1.Modified := False;
    
    // Сохраняем папку в реестр
    LastDir := ExtractFilePath(SaveDialog1.FileName);
    Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKey('\Software\DelphiEditor', True) then
      begin
        Reg.WriteString('LastDirectory', LastDir);
        Reg.CloseKey;
      end;
    finally
      Reg.Free;
    end;

    // Сохраняем путь к сохраненному файлу в реестр
    Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKey('\Software\DelphiEditor', True) then
      begin
        Reg.WriteString('LastFile', SaveDialog1.FileName);
        Reg.CloseKey();
      end;
    finally
      Reg.Free;
    end;
  end;
end;

procedure TForm1.CutClick(Sender: TObject);
begin
  SynEdit1.CutToClipboard;
end;

procedure TForm1.CopyClick(Sender: TObject);
begin
  SynEdit1.CopyToClipboard;
end;

procedure TForm1.PasteClick(Sender: TObject);
begin
  SynEdit1.PasteFromClipboard;
end;

procedure TForm1.DeleteClick(Sender: TObject);
begin
  SynEdit1.ClearSelection;
end;

procedure TForm1.FontSizeClick(Sender: TObject);
begin
  FontDialog1.Font := SynEdit1.Font;
  if FontDialog1.Execute then
  begin
    SynEdit1.Font := FontDialog1.Font;
    SynEdit1.Gutter.Font := FontDialog1.Font;
  end;
end;

procedure TForm1.FontColorClick(Sender: TObject);
begin
  ColorDialog1.Color := SynEdit1.Font.Color;
  if ColorDialog1.Execute then
    SynEdit1.Font.Color := ColorDialog1.Color;
end;

procedure TForm1.CheckSyntaxBtnClick(Sender: TObject);
begin
  CheckSyntax;
end;

procedure TForm1.CheckSyntax;
begin
  // Сбрасываем предыдущую ошибку, если была
  if FErrorLine >= 0 then
  begin
    SynEdit1.InvalidateLine(FErrorLine + 1); // Перерисовываем предыдущую строку с ошибкой
    FErrorLine := -1;
  end;
  
  StatusBar1.Panels[2].Text := '';
  
  // Проверяем баланс скобок
  CheckParenthesesBalance;
  
  // Проверяем использование точек с запятой
  CheckSemicolonUsage;
  
  // Проверяем баланс if/then
  CheckIfThenBalance;
  
  // Проверяем объявления процедур и функций
  CheckProcedureFunctionDeclarations;
  
  // Проверяем объявления переменных
  CheckVariableDeclarations;
  
  // Проверяем объявления типов
  CheckTypeDeclarations;
  
  // Проверяем объявления констант
  CheckConstantDeclarations;
  
  if StatusBar1.Panels[2].Text = '' then
    StatusBar1.Panels[2].Text := 'Проверка синтаксиса завершена - ошибок не найдено';
end;

procedure TForm1.CheckParenthesesBalance;
var
  I, ParenCount: Integer;
begin
  ParenCount := 0;
  
  for I := 1 to Length(SynEdit1.Text) do
  begin
    if SynEdit1.Text[I] = '(' then
      Inc(ParenCount)
    else if SynEdit1.Text[I] = ')' then
      Dec(ParenCount);
      
    if ParenCount < 0 then
    begin
      ShowError('Незакрытые скобки', -1);
      Break;
    end;
  end;
  
  if ParenCount > 0 then
    ShowError('Незакрытые скобки', -1);
end;

procedure TForm1.CheckSemicolonUsage;
var
  I: Integer;
  Line, NextLine: string;
begin
  for I := 0 to SynEdit1.Lines.Count - 2 do // Проверяем до предпоследней строки, чтобы иметь доступ к NextLine
  begin
    Line := Trim(SynEdit1.Lines[I]);
    NextLine := LowerCase(Trim(SynEdit1.Lines[I + 1]));

    // Пропускаем комментарии и директивы компилятора
    if (Line <> '') and
       (((Length(Line) >= 2) and (Line[1] = '/') and (Line[2] = '/')) or // Комментарии //
        ((Length(Line) >= 2) and (Line[1] = '{') and (Line[2] = '$')) or // Директивы компилятора {$
        ((Length(Line) >= 2) and (Line[1] = '{') and (Line[Length(Line)] = '}'))) then // Комментарии {}
      Continue;

    // Проверяем наличие точки с запятой, если строка не пустая и не заканчивается на исключающие ключевые слова или перед else
    if (Line <> '') and (Line[Length(Line)] <> ';') and
       (not lowercase(Line).EndsWith('begin')) and
       (not lowercase(Line).EndsWith('end.')) and
       (not lowercase(Line).EndsWith('repeat')) and
       (not lowercase(Line).EndsWith('then')) and
       (not lowercase(Line).EndsWith('else')) and
       (not lowercase(Line).EndsWith('do')) and
       (not lowercase(Line).EndsWith('of')) and
       (not lowercase(Line).EndsWith(':')) and
       (not lowercase(Line).EndsWith(',')) and
       (not lowercase(Line).EndsWith('try')) and
       (not lowercase(Line).EndsWith('except')) and
       (not lowercase(Line).EndsWith('finally')) and
       (not lowercase(Line).EndsWith('until')) and
       (not lowercase(Line).EndsWith('interface')) and
       (not lowercase(Line).EndsWith('implementation')) and
       (not lowercase(Line).EndsWith('initialization')) and
       (not lowercase(Line).EndsWith('finalization')) and
       (not lowercase(Line).EndsWith('const')) and
       (not lowercase(Line).EndsWith('type')) and
       (not lowercase(Line).EndsWith('var')) and
       (not lowercase(Line).EndsWith('class')) and
       (not lowercase(Line).EndsWith('public')) and
       (not lowercase(Line).EndsWith('private')) and
       (not lowercase(Line).EndsWith('protected')) and
       (not lowercase(Line).EndsWith('published')) and
       (not lowercase(Line).EndsWith('record')) and
       (not lowercase(Line).EndsWith('array')) and
       (not lowercase(Line).EndsWith('set')) and
       (not lowercase(Line).EndsWith('file')) and
       (not lowercase(Line).EndsWith('threadvar')) and
       (not lowercase(Line).EndsWith('exports')) and
       (not lowercase(Line).EndsWith('constructor')) and
       (not lowercase(Line).EndsWith('destructor')) and
       (not lowercase(Line).EndsWith('property')) and
       (not lowercase(Line).EndsWith('procedure')) and
       (not lowercase(Line).EndsWith('function')) and
       (not lowercase(Line).EndsWith('try')) and
       (not lowercase(Line).EndsWith('except')) and
       (not lowercase(Line).EndsWith('finally')) and
       (not lowercase(Line).EndsWith('repeat')) and
       (not lowercase(Line).EndsWith('until')) and
       (not lowercase(Line).EndsWith('uses')) and
       (not lowercase(Line).EndsWith('and')) and
       (not lowercase(Line).EndsWith('or')) and
       (not lowercase(Line).EndsWith('div')) and
       (not lowercase(Line).EndsWith('mod')) and
       (not lowercase(Line).EndsWith('in')) and
       (not lowercase(Line).EndsWith('is')) and
       (not lowercase(Line).EndsWith('as')) and
       (not lowercase(Line).EndsWith('shl')) and
       (not lowercase(Line).EndsWith('shr')) and
       (not lowercase(Line).EndsWith('+')) and
       (not lowercase(Line).EndsWith('-')) and
       (not lowercase(Line).EndsWith('*')) and
       (not lowercase(Line).EndsWith('/')) and
       (not lowercase(Line).EndsWith('=')) and
       (not lowercase(Line).EndsWith('<>')) and
       (not lowercase(Line).EndsWith('<')) and
       (not lowercase(Line).EndsWith('>')) and
       (not lowercase(Line).EndsWith('<=')) and
       (not lowercase(Line).EndsWith('>=')) and
       (not lowercase(Line).EndsWith('^')) and
       (not lowercase(Line).EndsWith('.')) and
       (not lowercase(NextLine).StartsWith('else')) and
       (not ((Pos(' class', LowerCase(Line)) > 0) and (Pos('=', NextLine) = 0)))
    then
    begin
      ShowError('Пропущена точка с запятой', I + 1);
    end;

    // Добавляем проверку на наличие ';' перед 'else' на следующей строке
    // Эта проверка также должна учитывать часть оператора до комментария
    if (Line <> '') and (Line[Length(Line)] = ';') and NextLine.StartsWith('else') then
    begin
      ShowError('; не разрешена перед else', I + 1); // Указываем строку, где найдена ';'
    end;
  end;

  // Отдельная проверка для последней строки (без проверки NextLine)
  if SynEdit1.Lines.Count > 0 then
  begin
    Line := Trim(SynEdit1.Lines[SynEdit1.Lines.Count - 1]);

    // Пропускаем комментарии и директивы компилятора
    if (Line <> '') and
       (((Length(Line) >= 2) and (Line[1] = '/') and (Line[2] = '/')) or // Комментарии //
        ((Length(Line) >= 2) and (Line[1] = '{') and (Line[2] = '$')) or // Директивы компилятора {$
        ((Length(Line) >= 2) and (Line[1] = '{') and (Line[Length(Line)] = '}'))) then // Комментарии {}
      Exit;

    // Проверяем, если последняя строка оператора не пустая и не заканчивается '.' или ';', и не является концом блока (end., end;)
    if (Line <> '') and (Line[Length(Line)] <> '.') and (Line[Length(Line)] <> ';') and
       (not LowerCase(Line).EndsWith('end.')) and (not LowerCase(Line).EndsWith('end;')) then
    begin
       // В простом анализаторе сложно точно определить, нужна ли ';' на последней строке. Оставим пока без ошибки.
       // ShowError('Potential missing semicolon at end of file', SynEdit1.Lines.Count);
    end;
  end;
end;

procedure TForm1.CheckIfThenBalance;
var
  I: Integer;
  Line: string;
  IfCount, ThenCount: Integer;
  LastIfLine, FirstThenLine: Integer;
begin
  IfCount := 0;
  ThenCount := 0;
  LastIfLine := -1;
  FirstThenLine := -1;
  
  for I := 0 to SynEdit1.Lines.Count - 1 do
  begin
    Line := LowerCase(Trim(SynEdit1.Lines[I]));
    if Pos('if ', Line) > 0 then
    begin
      Inc(IfCount);
      LastIfLine := I + 1; // Запоминаем номер строки (1-индексированный)
    end;
    if Pos(' then', Line) > 0 then
    begin
      Inc(ThenCount);
      if FirstThenLine = -1 then
        FirstThenLine := I + 1; // Запоминаем номер первой строки с then
    end;
  end;
  
  if IfCount > ThenCount then
    ShowError('Пропущен "then" для "if"', LastIfLine)
  else if ThenCount > IfCount then
    ShowError('Лишний "then" без "if"', FirstThenLine);
end;

procedure TForm1.CheckProcedureFunctionDeclarations;
var
  I: Integer;
  Line: string;
begin
  for I := 0 to SynEdit1.Lines.Count - 1 do
  begin
    Line := LowerCase(Trim(SynEdit1.Lines[I]));

    // Проверка объявления функции - по-прежнему проверяем наличие типа возврата
    if (Pos('function ', Line) > 0) and (Pos(':', Line) = 0) then
      ShowError('В объявлении функции пропущен тип возврата', I + 1);

  end;
end;

procedure TForm1.CheckVariableDeclarations;
var
  I: Integer;
  Line: string;
begin
  for I := 0 to SynEdit1.Lines.Count - 1 do
  begin
    Line := LowerCase(Trim(SynEdit1.Lines[I]));
    
    // Проверка объявления переменной
    if (Pos('var ', Line) > 0) and (Pos(':', Line) = 0) then
      ShowError('В объявлении переменной пропущен тип', I + 1);
      
    // Проверка множественного объявления
    if (Pos('var ', Line) > 0) and (Pos(',', Line) > 0) and (Pos(':', Line) = 0) then
      ShowError('В множественном объявлении переменной пропущен тип', I + 1);
  end;
end;

procedure TForm1.CheckTypeDeclarations;
var
  I: Integer;
  Line, PrevLine: string;
  InTypeBlock: Boolean;
  HasTypeDefinition: Boolean;
begin
  InTypeBlock := False;
  HasTypeDefinition := False;
  for I := 0 to SynEdit1.Lines.Count - 1 do
  begin
    Line := LowerCase(Trim(SynEdit1.Lines[I]));
    if I > 0 then
      PrevLine := LowerCase(Trim(SynEdit1.Lines[I - 1]))
    else
      PrevLine := '';
    
    // Проверяем начало блока type
    if StartsText('type', Line) then
    begin
      InTypeBlock := True;
      Continue;
    end;
    
    // Проверяем конец блока type
    if InTypeBlock and (StartsText('var', Line) or StartsText('const', Line) or
                       StartsText('procedure', Line) or StartsText('function', Line) or
                       StartsText('implementation', Line) or StartsText('initialization', Line) or
                       StartsText('finalization', Line) or StartsText('begin', Line)) then
    begin
      InTypeBlock := False;
      HasTypeDefinition := False;
    end;
    
    // Проверяем объявление типа только внутри блока type
    if InTypeBlock then
    begin
      // Если в текущей или предыдущей строке есть знак =, значит это объявление типа
      if (Pos('=', Line) > 0) or (Pos('=', PrevLine) > 0) then
        HasTypeDefinition := True;
        
      // Проверка объявления типа
      if (Line <> '') and (not StartsText('(', Line)) and (not HasTypeDefinition) and
         (not StartsText('end', Line)) and (not StartsText('record', Line)) then
        ShowError('В объявлении типа пропущено определение', I + 1);
        
      // Проверка объявления record только если это действительно объявление типа
      if (Pos('record', Line) > 0) and (Pos('=', Line) = 0) and (Pos('=', PrevLine) = 0) then
        ShowError('В объявлении record пропущено определение типа', I + 1);
    end;
  end;
end;

procedure TForm1.CheckConstantDeclarations;
var
  I: Integer;
  Line: string;
  InConstBlock: Boolean; // Flag to track if we are inside a const block
begin
  InConstBlock := False;
  for I := 0 to SynEdit1.Lines.Count - 1 do
  begin
    Line := LowerCase(Trim(SynEdit1.Lines[I]));

    // Check for the start of a const block
    if StartsText('const', Line) then
    begin
      InConstBlock := True;
      Continue; // Move to the next line
    end;

    // Check for the end of a const block (could be var, type, procedure, function, implementation, initialization, finalization, or begin)
    if InConstBlock and (StartsText('var', Line) or StartsText('type', Line) or
                        StartsText('procedure', Line) or StartsText('function', Line) or
                        StartsText('implementation', Line) or StartsText('initialization', Line) or
                        StartsText('finalization', Line) or StartsText('begin', Line)) then
    begin
      InConstBlock := False;
    end;

    // If inside a const block and line is not empty and does not contain '=', it's likely a missing value
    if InConstBlock and (Line <> '') and (Pos('=', Line) = 0) and (not StartsText('(', Line)) then // Exclude attribute lists like [deprecated]
    begin
      ShowError('В объявлении константы пропущено значение', I + 1);
    end;

  end;
end;

function TForm1.CountOccurrences(const SubStr, Str: string): Integer;
var
  Offset: Integer;
begin
  Result := 0;
  Offset := Pos(SubStr, Str);
  while Offset <> 0 do
  begin
    Inc(Result);
    Offset := PosEx(SubStr, Str, Offset + Length(SubStr));
  end;
end;

procedure TForm1.ShowError(const ErrorMsg: string; LineNumber: Integer = -1);
begin
  if StatusBar1.Panels.Count > 2 then
  begin
    StatusBar1.Panels[2].Text := 'Error: ' + ErrorMsg;
    
    // Сбрасываем предыдущую ошибку, если была
    if FErrorLine >= 0 then
    begin
      SynEdit1.InvalidateLine(FErrorLine + 1); // Перерисовываем предыдущую строку с ошибкой
      FErrorLine := -1;
    end;
    
    if LineNumber > 0 then
    begin
      StatusBar1.Panels[2].Text := StatusBar1.Panels[2].Text + ' в строке ' + IntToStr(LineNumber);
      FErrorLine := LineNumber - 1; // FErrorLine хранится с 0-индексом
      SynEdit1.InvalidateLine(LineNumber); // Перерисовываем строку с ошибкой
    end;
  end;
end;

procedure TForm1.NewClick(Sender: TObject);
var
  CanContinue: Boolean; // Переменная для отслеживания, можно ли продолжить создание нового файла
begin
  CanContinue := True; // По умолчанию разрешаем продолжить
  
  if SynEdit1.Modified then // Проверяем, были ли изменения
  begin
    case MessageDlg('Документ изменен. Сохранить изменения?', mtConfirmation,
      [mbYes, mbNo, mbCancel], 0) of
      mrYes:
        SaveClick(Sender); // Сохраняем изменения
      mrCancel:
        CanContinue := False; // Отменяем создание нового файла
    end;
  end;
  
  if CanContinue then // Если разрешено продолжить
  begin
    SynEdit1.Clear;
    FileName := '';
    StatusBar1.Panels[2].Text := '';
    
    // Обновляем информацию о количестве строк и символов
    StatusBar1.Panels[0].Text := 'Символов: ' + IntToStr(Length(SynEdit1.Text));
    StatusBar1.Panels[1].Text := 'Строк: ' + IntToStr(SynEdit1.Lines.Count);
    
    // Сбрасываем ошибку и подсветку
    if FErrorLine >= 0 then
    begin
      SynEdit1.InvalidateLine(FErrorLine + 1); // Перерисовываем предыдущую строку с ошибкой
      FErrorLine := -1;
    end;
  end;
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
  Close; // Просто закрываем форму, проверка сохранения будет в FormCloseQuery
end;

procedure TForm1.SynEdit1Change(Sender: TObject);
begin
  StatusBar1.Panels[0].Text := 'Символов: ' + IntToStr(Length(SynEdit1.Text));
  StatusBar1.Panels[1].Text := 'Строк: ' + IntToStr(SynEdit1.Lines.Count);

  // Сбрасываем ошибку и подсветку при изменении текста
  if FErrorLine >= 0 then
  begin
    SynEdit1.InvalidateLine(FErrorLine + 1); // Перерисовываем предыдущую строку с ошибкой
    FErrorLine := -1;
    StatusBar1.Panels[2].Text := '';
  end;
end;

procedure TForm1.SynEdit1Paint(Sender: TObject);
begin
  // Оставляем пустым
end;

procedure TForm1.SynEdit1SpecialLineColors(Sender: TObject; Line: Integer;
  var Special: Boolean; var FG, BG: TColor);
begin
  // Проверяем, является ли текущая строка строкой с ошибкой (учитываем 1-индексацию Line)
  if (FErrorLine >= 0) and (Line = FErrorLine + 1) then // Сравниваем 1-индексированный Line с 0-индексированным FErrorLine + 1
  begin
    Special := True; // Указываем, что строка особая
    BG := clRed; 
    FG := clBlack; 
  end
  else
  begin
    Special := False; // Строка не особая, использовать стандартные цвета
  end;
end;

procedure TForm1.ConfigureSyntaxColors;
begin
  with SynPasSyn1 do
  begin
    // Основные цвета
    CommentAttri.Foreground := clGreen;
    CommentAttri.Style := [fsItalic];
    
    // Ключевые слова
    KeyAttri.Foreground := clNavy;
    KeyAttri.Style := [fsBold];
    
    // Строки
    StringAttri.Foreground := clMaroon;
    
    // Числа
    NumberAttri.Foreground := clBlue;
    
    // Идентификаторы
    IdentifierAttri.Foreground := clBlack;
    
    // Директивы компилятора
    DirectiveAttri.Foreground := clPurple;
    DirectiveAttri.Style := [fsBold];
    
    // Символы
    SymbolAttri.Foreground := clRed;
    
    // Типы
    TypeAttri.Foreground := clOlive;
    TypeAttri.Style := [fsBold];
  end;
  
  SynEdit1.Invalidate;
end;

procedure TForm1.CopyStatusText1Click(Sender: TObject);
begin
  if StatusBar1.Panels.Count > 2 then
  begin
    Clipboard.AsText := StatusBar1.Panels[2].Text;
  end;
end;

end.
