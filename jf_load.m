function [d]=jf_load(expt,subj,label,session,errorp,mionly,verb);
% load a pre-saved jf-data-struct
%
%  [z]=load(expt,subj,label,session,errorp,mionly,verb)
%   OR
%  [z]=load(d)
% Inputs:
%  expt  -- [str] experiment name
%  subj  -- [str] subject name
%  label -- [str] pre-processing label
%  session--[str] session id
%  d     -- [struct] containing d.expt,d.subj,d.label to extract from
%  errorp-- [bool] flag if its an error to not find the dataset
%                  1 -> list possible files, and error
%                  0 -> list positive files
%                  -1-> say nothing
%  mionly-- [bool] only load the meta-info for speed
%  verb  -- [int] verbosity level
global bciroot; 
if(isempty(bciroot)) bciroot={glob('~/data/bci')}; 
elseif(~iscell(bciroot)) bciroot={bciroot}; 
end;
if ( nargin<7 || isempty(verb) )   verb=0; end;
if ( nargin<6 || isempty(mionly) ) mionly=0; end;
if ( nargin<5 || isempty(errorp) ) errorp=1; end;
if ( nargin<4 ) session=''; end;
if ( ~isempty(session) && isnumeric(session) && session<2 && session>=0 && nargin==4 ) errorp=session; session=''; end;
if ( nargin<3 && isstruct(expt) ) 
   if ( nargin>1 && (isnumeric(subj) || islogical(subj)) ) errorp=subj; end;
   z=expt; expt=z.expt; subj=z.subj; label=z.label;
   if ( isfield(z,'session') ) session=z.session; else session=''; end;
 end;
if ( iscell(session) ) if ( isempty(session) ) session=''; elseif ( numel(session)<=1 ) session=session{:}; end; end;

bciroots=bciroot;
if ( isequal(expt(1),'~') || isequal(expt(1),filesep()) )
  bciroots={''};
end

fname=sprintf('%s_%s',subj,label);
d=[];
warnstr='';
for ri=1:numel(bciroots);

   % Search for a directory
   rootdir=bciroots{ri};
   if (verb>0) fprintf('Trying root : %s\n',rootdir); end;
   sdir = fullfile(expt,subj);
   if (verb>0) fprintf('Searching : %s\n',sdir); end;
   if ( ~exist(fullfile(rootdir,sdir),'dir') ) % try with subjects bit
      sdir=fullfile(expt,'subjects',subj);
      if ( ~exist(fullfile(rootdir,sdir),'dir') ) 
        if ( verb>0 ) fprintf('subject dir not found!\n'); end;
        continue; 
      end;
   end
   fdir = fullfile(rootdir,sdir,session); % session dir over-rides if exists
   if ( ~exist(fdir,'dir') ) % use the subject dir
      if ( ~isempty(session) ) 
         warning('no per-session info found, using per-subject'); 
      end;
      fdir=fullfile(rootdir,sdir);
      if ( ~exist(fdir,'dir') ) continue; end; % if not there skip
   end;
   if ( verb>0 ) fprintf('Found : %s\n',fdir); end;
   if ( exist(fullfile(fdir,'jf_prep'),'dir') )
      fdir=fullfile(fdir,'jf_prep');
   else
      warning('no jf_prep sub-directory found, using parent directory');
   end

   % search for file-name in directory
   if ( verb>0 ) fprintf('Searching in directory for files : %s\n',fdir); end;
   fn = fullfile(fdir,fname);
   if ( ~exist([fn '.mat'],'file') ) % try without the subject prefix
      fn = fullfile(fdir,label);
   end
   if ( ~exist([fn '.mat'],'file') )
      D=dir([fdir '/*.mat']); D([D.isdir])=[];
      warnstr=sprintf('%s\nDir: %s',warnstr,fdir);
      warnstr=sprintf('%s\n ',warnstr,D.name);
   else
      fprintf('Loading: %s\n',fn);
      if ( mionly ) 
         d=load(fn,'prep','summary','di');
      else
         d=load(fn);
      end
      fprintf('done\n');
      fn=fieldnames(d); if(numel(fn)==1 && isstruct(getfield(d,fn{1}))) d=getfield(d,fn{1}); end;
      if ( numel(d)>1 ) % deal with arrays of data objects
        for di=1:numel(d); d(di).rootdir=rootdir; end;
      else
        d.rootdir = rootdir;
        d.subjdir = sdir ; % where we came from & should save to
        d.expt=expt;
        d.subj=subj;
        d.label=label;
        d.session=session;
      end
      break;
   end
end
if ( isempty(d) && errorp>=0 ) 
   warning('Couldnt match %s\nPossible file names are\n%s',fname,warnstr);
   if ( errorp ) error('Couldnt find a match for this file');  end;
end;
return;
%------------------------------------------------------------------------
function testCases()
z=jf_load('eeg/test','test','test','1');



