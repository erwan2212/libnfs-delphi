unit libnfs;

interface

uses windows,sysutils,classes;

const
O_RDONLY=	$0000;		//* open for reading only */
O_WRONLY=	$0001;		//* open for writing only */
O_RDWR=		$0002;		//* open for reading and writing
O_ACCMODE=	$0003;

O_CREAT=	$0100;
O_TRUNC=	$1000;
O_APPEND=	$2000;
O_NONBLOCK=	$4000;
O_EXCL=	$0200;
{
#define O_CREAT		0x0100	/* second byte, away from DOS bits */
#define O_EXCL		0x0200
#define O_NOCTTY	0x0400
#define O_TRUNC		0x0800
#define O_APPEND	0x1000
#define O_NONBLOCK	0x2000
}
//
 	S_IFDIR   =$0040000;
 	S_IFREG   =$0100000;
 	S_IFCHR   =$0020000;
 	S_IFBLK   =$0060000;
 	S_IFLNK   =$0120000;
  S_IFMT    =$0170000;

type
   pnfs_url=^tnfs_url;
   tnfs_url =record
	 server:pchar;
	 path:pchar;
	 file_:pchar;
 end;

 type
 pnfs_server_list=^tnfs_server_list;
 tnfs_server_list =record
       next:pointer;
       addr:pchar;
  end;

  type
  pexportnode=^texportnode;
  texportnode =record
	ex_dir:pchar;
	ex_groups:pointer;
	ex_next:pointer;
end;


 type
 pnfsdirent=^tnfsdirent;
 tnfsdirent =record
        next:pointer;
        name:pchar;
        inode:int64;
       //* Some extra fields we get for free through the READDIRPLUS3 call.
	  //You need libnfs-raw-nfs.h for type/mode constants */
        type_:dword; //* NF3REG, NF3DIR, NF3BLK, ... */
        mode:dword;
        size:int64;
         atime:array[0..15] of byte;  //timeval
         mtime:array[0..15] of byte;  //timeval
         ctime:array[0..15] of byte;  //timeval
        uid:dword;
        gid:dword;
        nlink:dword;
        dev:int64;
        rdev:int64;
        blksize:int64;
        blocks:int64;
        used:int64;
        atime_nsec:dword;
        mtime_nsec:dword;
        ctime_nsec:dword;
end;

type nfs_stat_64 =record
	 nfs_dev:int64;
	 nfs_ino:int64;
	 nfs_mode:int64;
	 nfs_nlink:int64;
	 nfs_uid:int64;
	 nfs_gid:int64;
	 nfs_rdev:int64;
	 nfs_size:int64;
	 nfs_blksize:int64;
	 nfs_blocks:int64;
	 nfs_atime:int64;
	 nfs_mtime:int64;
	 nfs_ctime:int64;
	 nfs_atime_nsec:int64;
	 nfs_mtime_nsec:int64;
	 nfs_ctime_nsec:int64;
	 nfs_used:int64;
end;


var
  nfs_init_context:function():pointer ; cdecl;
  nfs_destroy_context:procedure(nfs:pointer); cdecl;
  nfs_parse_url_full:function(nfs:pointer;url:pchar):pointer;cdecl;
  nfs_destroy_url:procedure(nfsurl:pointer);cdecl;
  nfs_get_error:function(nfs:pointer):pchar;cdecl;
  nfs_mount:function(nfs:pointer;server:pchar;exportname:pchar):integer; cdecl;
  //file
  nfs_creat:function(nfs:pointer; path:pchar;mode:integer;nfsfh:ppointer):integer; cdecl;
  nfs_open:function(nfs:pointer;path:pchar;flags:integer;nfsfh:ppointer):integer; cdecl;
  //
  nfs_read:function(nfs:pointer; nfsfh:pointer;count:int64;buf:pointer):integer; cdecl;
  nfs_write:function(nfs:pointer; nfsfh:pointer;count:int64;buf:pointer):integer; cdecl;
  //p = position
  nfs_pread:function(nfs:pointer; nfsfh:pointer;offset:int64;count:int64;buf:pointer):integer; cdecl;
  nfs_pwrite:function(nfs:pointer; nfsfh:pointer;offset:int64;count:int64;buf:pointer):integer; cdecl;
  //
  nfs_lseek:function(nfs:pointer; nfsfh:pointer;offset:int64;whence:integer;current_offset:pint64):integer; cdecl;
  //stat
  nfs_fstat64:function(nfs:pointer; nfsfh:pointer;st:pointer):integer; cdecl;
  nfs_stat64:function(nfs:pointer;path:pchar;st:pointer):integer; cdecl;
  //
  nfs_close:function(nfs:pointer; nfsfh:pointer):integer; cdecl;
  //directory
  nfs_opendir:function( nfs:pointer; path:pchar;nfsdir:ppointer):integer; cdecl;
  nfs_readdir:function(nfs:pointer;nfsdir:pointer):pointer;cdecl;
  nfs_closedir:procedure(nfs:pointer;nfsdir:pointer);cdecl;
  nfs_getcwd:procedure(nfs:pointer;cwd:ppointer);cdecl;
  nfs_chdir:function(nfs:pointer; path:pchar):integer; cdecl;
  //
  nfs_find_local_servers:function():pointer;cdecl;
  free_nfs_srvr_list:procedure(srv:pointer);cdecl;
  //
  mount_getexports:function(server:pchar):pointer;cdecl;
  mount_free_export_list:procedure(exports_:pointer);cdecl;
  //With ftruncate(), the file must be open for writing; with truncate(), the file must be writable.
  nfs_truncate:function(nfs:pointer; path:pchar;length:int64):integer; cdecl;

procedure lib_init;
procedure lib_free;
function nfsdiscover(items:tstrings):boolean;
function nfsreadfile2(path,local:string):boolean;
function nfswritefile2(path,local:string):int64;
function nfsreadfile3(path:string):boolean;

var
fLibHandle:thandle=thandle(-1);
nfs:pointer=nil;

implementation

//var
//fLibHandle:thandle=thandle(-1);

procedure lib_free;
begin
FreeLibrary(fLibHandle);
end;

procedure lib_init;
begin
fLibHandle:=thandle(-1);
fLibHandle:=LoadLibraryA(PAnsiChar('libnfs.dll'));
if fLibHandle <=0 then
  begin
  raise exception.create('LoadLibraryA failed');
  exit;
  end;
//
@nfs_init_context:=GetProcAddress(fLibHandle,'nfs_init_context');
@nfs_parse_url_full:=GetProcAddress(fLibHandle,'nfs_parse_url_full');
@nfs_get_error:=GetProcAddress(fLibHandle,'nfs_get_error');
@nfs_mount:=GetProcAddress(fLibHandle,'nfs_mount');
@nfs_open:=GetProcAddress(fLibHandle,'nfs_open');
@nfs_read:=GetProcAddress(fLibHandle,'nfs_read');
@nfs_write:=GetProcAddress(fLibHandle,'nfs_write');
@nfs_pread:=GetProcAddress(fLibHandle,'nfs_pread');
@nfs_pwrite:=GetProcAddress(fLibHandle,'nfs_pwrite');
@nfs_close:=GetProcAddress(fLibHandle,'nfs_close');
@nfs_destroy_url:=GetProcAddress(fLibHandle,'nfs_destroy_url');
@nfs_destroy_context:=GetProcAddress(fLibHandle,'nfs_destroy_context');
@nfs_opendir:=GetProcAddress(fLibHandle,'nfs_opendir');
@nfs_readdir:=GetProcAddress(fLibHandle,'nfs_readdir');
@nfs_closedir:=GetProcAddress(fLibHandle,'nfs_closedir');
@nfs_lseek:=GetProcAddress(fLibHandle,'nfs_lseek');
@nfs_fstat64:=GetProcAddress(fLibHandle,'nfs_fstat64');
@nfs_stat64:=GetProcAddress(fLibHandle,'nfs_stat64');
@nfs_getcwd:=GetProcAddress(fLibHandle,'nfs_getcwd');
@nfs_chdir:=GetProcAddress(fLibHandle,'nfs_chdir');
@nfs_find_local_servers:=GetProcAddress(fLibHandle,'nfs_find_local_servers');
@free_nfs_srvr_list:=GetProcAddress(fLibHandle,'free_nfs_srvr_list');
@mount_getexports:=GetProcAddress(fLibHandle,'mount_getexports');
@mount_free_export_list:=GetProcAddress(fLibHandle,'mount_free_export_list');
@nfs_creat:=GetProcAddress(fLibHandle,'nfs_creat');
@nfs_truncate:=GetProcAddress(fLibHandle,'nfs_truncate');

//
end;

function nfsgetexports(server:string; items:TStrings ):boolean;
var
exports_,p2:pexportnode;
begin
exports_:=mount_getexports(pchar(server));
p2:= exports_;
if p2^.ex_dir<>nil then  items.add('nfs://'+server+strpas(p2^.ex_dir )+'/');
while p2^.ex_next <>nil do
begin
//Inc(PByte(P2),sizeof(texportnode)); //unsafe
p2:=p2^.ex_next;
items.add('nfs://'+server+strpas(p2^.ex_dir )+'/');
end;
if exports_ <>nil then mount_free_export_list(exports_ );
end;

function nfsdiscover(items:tstrings):boolean;
var
srv,p1:pnfs_server_list ;

begin
if libnfs.fLibHandle =thandle(-1) then lib_init;
srv:=nil;
srv:=nfs_find_local_servers;
if srv<>nil then
begin
p1:=srv;
if p1^.addr<>nil then nfsgetexports(strpas(p1^.addr ),Items );
while p1^.next<>nil do
begin
p1:=p1^.next;
if p1^.addr<>nil then nfsgetexports(strpas(p1^.addr ),Items );
end;
if srv<>nil then free_nfs_srvr_list(srv);
end;
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

end.

