unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,winsock,libnfs, ComCtrls, Menus,shellapi;

type
  TForm1 = class(TForm)
    Button2: TButton;
    ListView1: TListView;
    txtpath: TEdit;
    PopupMenu1: TPopupMenu;
    ReadFile1: TMenuItem;
    Button1: TButton;
    DownloadFile1: TMenuItem;
    Button3: TButton;
    txtnfs: TComboBox;
    Button4: TButton;
    N1: TMenuItem;
    Refresh1: TMenuItem;
    UploadFile1: TMenuItem;
    OpenDialog1: TOpenDialog;
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button2Click(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ReadFile1Click(Sender: TObject);
    procedure DownloadFile1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Refresh1Click(Sender: TObject);
    procedure UploadFile1Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure ListView1ColumnClick(Sender: TObject; Column: TListColumn);
  private
    { Private declarations }
    function nfslistdir(path:string):boolean;
  public
    { Public declarations }
  end;

type
 TCustomSortStyle = (cssAlphaNum, cssNumeric, cssDateTime,cssAlphaIP);
TLvSortOrder=array[0..4] of Boolean; // High[LvSortOrder] = Number of Lv Columns

var
  Form1: TForm1;
  //nfs:pointer=nil;
 { variable to hold the sort style }
  LvSortStyle: TCustomSortStyle;
  { array to hold the sort order }
  LvSortOrder: TLvSortOrder; //array[0..4] of Boolean; // High[LvSortOrder] = Number of Lv Columns





implementation

uses Unit2;

{$R *.dfm}

function CustomSortProc(Item1, Item2: TListItem; SortColumn: Integer): Integer; stdcall;
var
  s1, s2: string;
  i1, i2: Integer;
  r1, r2: Boolean;
  d1, d2: TDateTime;

  { Helper functions }

  function IsValidNumber(AString : string; var AInteger : Integer): Boolean;
  var
    Code: Integer;
  begin
    Val(AString, AInteger, Code);
    Result := (Code = 0);
  end;

  function IsValidDate(AString : string; var ADateTime : TDateTime): Boolean;
  begin
    Result := True;
    try
      ADateTime := StrToDateTime(AString);
    except
      ADateTime := 0;
      Result := False;
    end;
  end;

  function CompareDates(dt1, dt2: TDateTime): Integer;
  begin
    if (dt1 > dt2) then Result := 1
    else
      if (dt1 = dt2) then Result := 0
    else
      Result := -1;
  end;

  function CompareNumeric(AInt1, AInt2: Integer): Integer;
  begin
    if AInt1 > AInt2 then Result := 1
    else
      if AInt1 = AInt2 then Result := 0
    else
      Result := -1;
  end;

begin
  Result := 0;

  if (Item1 = nil) or (Item2 = nil) then Exit;

  case SortColumn of
    -1 :
    { Compare Captions }
    begin
      s1 := Item1.Caption;
      s2 := Item2.Caption;
    end;
    else
    { Compare Subitems }
    begin
      s1 := '';
      s2 := '';
      { Check Range }
      if (SortColumn < Item1.SubItems.Count) then
        s1 := Item1.SubItems[SortColumn];
      if (SortColumn < Item2.SubItems.Count) then
        s2 := Item2.SubItems[SortColumn]
    end;
  end;

  { Sort styles }

  case LvSortStyle of
    cssAlphaNum : Result := lstrcmp(PChar(s1), PChar(s2));
    cssNumeric  : begin
                    r1 := IsValidNumber(s1, i1);
                    r2 := IsValidNumber(s2, i2);
                    Result := ord(r1 or r2);
                    if Result <> 0 then
                      Result := CompareNumeric(i2, i1);
                  end;
    cssDateTime : begin
                    r1 := IsValidDate(s1, d1);
                    r2 := IsValidDate(s2, d2);
                    Result := ord(r1 or r2);
                    if Result <> 0 then
                      Result := CompareDates(d1, d2);
                  end;
{
    cssAlphaIp : begin
                    r1 := IsValidNumber(inttostr(ntohl(string2ip(s1))), i1);
                    r2 := IsValidNumber(inttostr(ntohl(string2ip(s2))), i2);
                    Result := ord(r1 or r2);
                    if Result <> 0 then
                      Result := CompareNumeric(i2, i1);
                end;
}
  end;

  { Sort direction }

  if LvSortOrder[SortColumn + 1] then
    Result := - Result;
end;

function GetTempFile(): string;
var
Buffer: array[0..MAX_PATH] OF Char;
begin
GetTempPath(Sizeof(Buffer)-1,Buffer);
GetTempFileName(Buffer,'~',0,Buffer);
result := StrPas(Buffer);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
if nfs<>nil then nfs_destroy_context(nfs);
nfs:=nil;
ListView1.Clear ;
txtpath.Text :='';
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin

if nfs<>nil then nfs_destroy_context(nfs);
//
lib_free;
end;

function nfsreadfile2(path,local:string):boolean;
var
nfsfh:pointer;
stat:nfs_stat_64;
buf:array[0..4096-1] of char;
count:integer;
//
FS: TFileStream;
filename:string;
begin
result:=false;
if nfs=nil then exit;
//context-full vs context-free?
if nfs_open (nfs,pchar(path) ,O_RDONLY ,@nfsfh)<>0  then raise exception.create(strpas( nfs_get_error(nfs)));
//
//if nfs_fstat64(nfs,nfsfh,@stat)<>0 then raise exception.create(strpas( nfs_get_error(nfs)));
//
fillchar(buf,sizeof(buf),0);
count := nfs_read(nfs, nfsfh, sizeof(buf), @buf[0]);
if count<0 then
  begin
  nfs_close(nfs, nfsfh);
  raise exception.create(strpas( nfs_get_error(nfs)));
  //exit;
  end
  else
  begin
  filename:=local;
  FS := TFileStream.Create(filename, fmOpenReadWrite or fmcreate);
  FS.Write(buf[0], count);
  while count>0 do
  begin
  fillchar(buf,sizeof(buf),0);
  count := nfs_read(nfs, nfsfh, sizeof(buf), @buf[0]);
  if count>0 then FS.Write(buf[0], count);
  end;
  FS.Free;
  result:=true;
  end;//if count<0 then

//
if nfs_close(nfs, nfsfh)<>0 then ;//raise exception.create(strpas( nfs_get_error(nfs)));
end;

function nfsreadfile3(path:string):boolean;
var
nfsfh:pointer;
stat:nfs_stat_64;
buf:array[0..4096-1] of char;
count:integer;
//
FS: TFileStream;
begin
result:=false;
if nfs=nil then exit;
//context-full vs context-free?
if nfs_open (nfs,pchar(path) ,O_RDONLY ,@nfsfh)<>0  then raise exception.create(strpas( nfs_get_error(nfs)));
//
//if nfs_fstat64(nfs,nfsfh,@stat)<>0 then raise exception.create(strpas( nfs_get_error(nfs)));
//
fillchar(buf,sizeof(buf),0);
count := nfs_read(nfs, nfsfh, sizeof(buf), @buf[0]);
if count<0 then
  begin
  nfs_close(nfs, nfsfh);
  raise exception.create(strpas( nfs_get_error(nfs)));
  end
  else
  begin
  {$i-}write(buf);{$i+}
  while count>0 do
  begin
  fillchar(buf,sizeof(buf),0);
  count := nfs_read(nfs, nfsfh, sizeof(buf), @buf[0]);
  if count>0 then {$i-}write(buf);{$i+}
  end;
  result:=true;
  end;//if count<0 then

//
if nfs_close(nfs, nfsfh)<>0 then ;//raise exception.create(strpas( nfs_get_error(nfs)));
end;

function nfswritefile2(path,local:string):int64;
var
nfsfh:pointer;
stat:nfs_stat_64;
buf:array[0..4096-1] of char;
count:integer;
//
FS: TFileStream;
filename:string;
begin
result:=0;
if nfs=nil then exit;
//context-full vs context-free
if nfs_creat(nfs,pchar(path),O_CREAT or O_RDWR,@nfsfh)<>0 then raise exception.create(strpas( nfs_get_error(nfs)));
//
  filename:=local;
  FS := TFileStream.Create(filename, fmOpenRead);
  while fs.Position < fs.Size do
  begin
  count:=FS.read(buf[0], 4096);
  if nfs_write(nfs, nfsfh, count, @buf[0])<>count  then
    begin
    nfs_close(nfs, nfsfh);
    raise exception.create('nfs_write error');
    //break;
    end;
  end;
  FS.Free;
//
if nfs_fstat64(nfs,nfsfh,@stat)<>0
  then //showmessage(strpas( nfs_get_error(nfs)));
  else result:=stat.nfs_size ;
//
if nfs_close(nfs, nfsfh)<>0 then ; //raise exception.create(strpas( nfs_get_error(nfs)));
end;



function tform1.nfslistdir(path:string):boolean;
var
nfsdirent:pnfsdirent ;
nfsdir:pointer;
stat:nfs_stat_64;
str_type,str_size:string;
li:tlistitem;
p:pchar;
begin
result:=false;
if nfs=nil then exit;
if nfs_opendir(nfs, pchar(path), @nfsdir) <>0 then raise exception.create(strpas( nfs_get_error(nfs)));
//
if nfs_chdir (nfs,pchar(path))<>0 then raise exception.create(strpas( nfs_get_error(nfs)));
//

getmem(p,1024);
nfs_getcwd (nfs,@p);
txtpath.text:=strpas(p);

//freemem(p);
//

nfsdirent := nfs_readdir(nfs, nfsdir);
ListView1.Clear ;
while nfsdirent <>nil do
  begin
  case (nfsdirent^.type_) of
     1:str_type :='<FILE>'; //filename
     2:str_type :='<DIR>';
     else str_type :='';
  end;
  if nfs_stat64(nfs,nfsdirent^.name,@stat)<>0 then
  begin
  //showmessage(strpas( nfs_get_error(nfs)));
  //exit;
  str_size :=''
  end
  else
  begin
  if str_type = '<DIR>'
    then str_size:=''
    else str_size :=inttostr(stat.nfs_size );
  end;
  li:=ListView1.Items.Add ;
  li.Caption :=nfsdirent^.name;
  li.SubItems.Add(str_size);
  li.SubItems.Add(str_type ) ;
  nfsdirent := nfs_readdir(nfs, nfsdir);
  end;
//
nfs_closedir(nfs,nfsdir );
result:=true;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
url: pnfs_url;
ret:boolean;
begin
if txtnfs.Text='' then exit;
if libnfs.fLibHandle =thandle(-1) then lib_init;
if nfs<>nil then begin showmessage('close context first');exit;end;
if nfs=nil then nfs:=nfs_init_context ;
//lets open a file
//nfsurl:=nfs_parse_url_full (nfs,pchar('nfs://192.168.1.248/volume2/public/clone.vmx'));
//lets open a folder
url:=nil;
if (txtnfs.Text [length(txtnfs.text)])<>'/' then txtnfs.Text:=txtnfs.Text+'/';
url:=nfs_parse_url_full (nfs,pchar(txtnfs.Text ));
if url=nil then
  begin
  showmessage(strpas( nfs_get_error(nfs)));
  exit;
  end;
//
if nfs_mount(nfs,url^.server , url^.path )<>0 then
  begin
  showmessage(strpas( nfs_get_error(nfs)));
  nfs_destroy_context (nfs);
  nfs:=nil;
  exit;
  end;
//we could do without URL if we only parsing...
nfs_destroy_url(url);
//
try
ret:=nfslistdir('/');
except
on e:exception do showmessage (e.Message );
end;
if ret=false then
  begin
  nfs_destroy_context (nfs);
  nfs:=nil;
  end;
//

end;

procedure TForm1.ListView1DblClick(Sender: TObject);
var
path,type_:string;
begin
if tlistview(sender).Selected=nil then exit;
path:=tlistview(sender).Selected.Caption;
type_:=tlistview(sender).Selected.SubItems [1];
if type_<>'<DIR>' then exit;
try
nfslistdir(path);
except
on e:exception do showmessage (e.Message );
end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
txtnfs.Clear ;
nfsdiscover(txtnfs.Items );
if txtnfs.Items.Count >1 then txtnfs.ItemIndex :=0;
end;

procedure TForm1.ReadFile1Click(Sender: TObject);
var
path,type_,size:string;
filename:string;
begin
if tlistview(listview1).Selected=nil then exit;
path:=tlistview(listview1).Selected.Caption;
size:=TListView (listview1).Selected.SubItems [0];
type_:=tlistview(listview1).Selected.SubItems [1];
if type_<>'<FILE>' then exit;
if strtoint64(size)>1024*1024
  then if MessageBox(0,'size is >1048576 bytes, continue','libnfs',mb_yesNo)=idno then exit;
filename:=GetTempFile;
try
if nfsreadfile2(path,filename)=true
  then ShellExecute(0,'open','notepad.exe',pchar(filename), nil, SW_SHOWNORMAL) ;
except
on e:exception do showmessage(e.Message );
end;

end;

procedure TForm1.DownloadFile1Click(Sender: TObject);
var
path,type_,size:string;
begin
if tlistview(listview1).Selected=nil then exit;
path:=tlistview(listview1).Selected.Caption;
size:=TListView (listview1).Selected.SubItems [0];
type_:=tlistview(listview1).Selected.SubItems [1];
if type_<>'<FILE>' then exit;
//if strtoint64(size)>1024*1024
//  then if MessageBox(0,'size is >1048576 bytes, continue','libnfs',mb_yesNo)=idno then exit;
try
if nfsreadfile2(path,ExtractFilePath (application.ExeName )+path)=true
  then   ShellExecute(Application.Handle, 'open', 'explorer.exe',PChar('"'+extractfilepath(application.ExeName)+'"'), nil, SW_NORMAL);
except
on e:exception do showmessage(e.Message );
end;

end;





procedure TForm1.FormCreate(Sender: TObject);
var
wsaData: TWSAData;
begin
//needed by libnfs
WSAStartup(MAKEWORD(2,2), wsaData);
//

end;

procedure TForm1.Refresh1Click(Sender: TObject);
begin
if txtpath.Text='' then exit;
try
nfslistdir(txtpath.Text );
except
on e:exception do showmessage (e.Message );
end;

end;

procedure TForm1.UploadFile1Click(Sender: TObject);
var
count:int64;
begin
if OpenDialog1.Execute=false then exit;
if OpenDialog1.FileName='' then exit;
try
count:=nfswritefile2('/'+ExtractFileName(OpenDialog1.FileName)  ,OpenDialog1.FileName);
showmessage(inttostr(count)+' bytes written');
except
on e:exception do showmessage(e.Message );
end;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
if nfs_truncate (nfs,'/menu.lst',0)<>0 then
  begin
  showmessage(strpas( nfs_get_error(nfs)));
  end;
end;

procedure TForm1.ListView1ColumnClick(Sender: TObject;
  Column: TListColumn);
begin
{ determine the sort style }

  if Column.Index = 0 then LvSortStyle := cssAlphaNum;
  if Column.Index = 1 then LvSortStyle := cssNumeric;
  if Column.Index = 2 then LvSortStyle := cssAlphaNum;


  { Call the CustomSort method }
  ListView1.CustomSort(@CustomSortProc, Column.Index -1);

  { Set the sort order for the column}
  LvSortOrder[Column.Index] := not LvSortOrder[Column.Index];
end;  

end.
 