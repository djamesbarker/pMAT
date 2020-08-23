function FastPrintv2(prefix, filename)
%Original code by David J. Barker; Modified by
%Carissa A. Bruno for the Barker Lab at Rutgers University.

mydir=cd;
%create a "Figures" folder if one does not already exist.
if isfolder([mydir '/Figures'])==0
    mkdir('Figures')
else
end
%To DO: If current directory=figures; up one level

originalname=strjoin([string(prefix),'_',string(filename)],'');
%Prevent the filename from beginning with an underscore if no figure is
%set.
if originalname{1}(1)=="_"
    originalname=string(originalname{1}(2:end));
end

a= [cd,'\Figures'];
mydir=cd;
cd(a)

nametype=strjoin([originalname,'.jpg'],'');
fullName=fullfile(a,nametype);

i=1;
while exist(fullName,'file')
    %Prevent previous files with the same name from being written over by 
    %adding a consecutive numerical suffix to the new file.
    filesuffix=i;
    anothernewname=strjoin([originalname,'_',string(filesuffix)],'');
    nametype=strjoin([anothernewname,'.jpg'],'');
    fullName=fullfile(a,nametype);
    if ~exist(fullName,'file')
        originalname=anothernewname;
    end
    i=i+1;
end

print(gcf,'-djpeg90','-r300',originalname); %save a jpeg file
savefig(originalname) %save a matlab figure
cd (mydir) %return to main folder
end

