program nfsclient;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  classes,winsock,windows,
  libnfs in 'libnfs.pas';

var
wsaData: TWSAData;
servers:tstrings;
i:integer;
url: pnfs_url=nil;
count:int64;

function nfslistdir(path:string):boolean;
var
nfsdirent:pnfsdirent ;
nfsdir:pointer;
stat:nfs_stat_64;
str_type,str_size:string;
p:pchar;
begin
result:=false;
if nfs=nil then exit;
if nfs_opendir(nfs, pchar(path), @nfsdir) <>0 then raise exception.create(strpas( nfs_get_error(nfs)));
//
if nfs_chdir (nfs,pchar(path))<>0 then raise exception.create(strpas( nfs_get_error(nfs)));
//

nfsdirent := nfs_readdir(nfs, nfsdir);

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
  writeln(str_type+#9+nfsdirent^.name+#9+str_size);
  nfsdirent := nfs_readdir(nfs, nfsdir);
  end;
//
nfs_closedir(nfs,nfsdir );
result:=true;
end;


begin
  { TODO -oUser -cConsole Main : Insert code here }
  lib_init ;
  WSAStartup(MAKEWORD(2,2), wsaData);
  //
  if ParamCount =0 then
    begin
    writeln('nfsclient 0.1 by erwan2212@gmail.com');
    writeln('nfsclient 0.1 discover');
    writeln('nfsclient 0.1 read nfs://server/export/filename');
    writeln('nfsclient 0.1 write nfs://server/export/ local_filename');
    writeln('nfsclient 0.1 dir nfs://server/export/');
    end;
  if lowercase(paramstr(1))='discover' then
    begin
    servers:=tstringlist.create;
    try
    nfsdiscover(servers );
    for i:=0 to servers.Count -1 do writeln(servers[i]);
    except
    on e:exception do writeln(e.message);
    end;
    servers.Free;
    end;
  //
  if lowercase(paramstr(1))='read' then
    begin
    nfs:=nfs_init_context;
    url:=nfs_parse_url_full (nfs,pchar(paramstr(2)));
    if url=nil
      then writeln('nfs_parse_url_full failed')
      else if nfs_mount(nfs,url^.server , url^.path )=0
        then nfsreadfile3(url^.file_ )
        else writeln ('mount failed');
    nfs_destroy_url(url);
    end;
  //
  if lowercase(paramstr(1))='write' then
    begin
    nfs:=nfs_init_context;
    url:=nfs_parse_url_full (nfs,pchar(paramstr(2)));
    if url=nil
      then writeln('nfs_parse_url_full failed')
      else if nfs_mount(nfs,url^.server , url^.path )=0
        then count:=nfswritefile2('/'+ExtractFileName(paramstr(3))  ,paramstr(3))
        else writeln ('nfs_mount failed');;
    writeln(inttostr(count)+' bytes written'); 
    nfs_destroy_url(url);
    end;
//
  if lowercase(ParamStr(1))='dir' then
    begin
    nfs:=nfs_init_context;
    url:=nfs_parse_url_full (nfs,pchar(paramstr(2)));
    if url=nil
      then writeln('nfs_parse_url_full failed')
      else if nfs_mount(nfs,url^.server , url^.path )=0
        then nfslistdir('/')
        else writeln ('nfs_mount failed');;
    nfs_destroy_url(url);
    end;
//
if nfs<>nil then nfs_destroy_context(nfs);
lib_free;
end.
