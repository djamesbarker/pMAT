function FastPrint(filename)
mydir=cd;
if isdir([mydir '/Figure'])==0
mkdir('Figure')
else
end
%To DO: If current directory=figures; up one level

a= [cd,'\Figure'];
mydir=cd;
cd(a)
print(gcf,'-djpeg90','-r300',filename);
savefig(filename)
cd (mydir)

