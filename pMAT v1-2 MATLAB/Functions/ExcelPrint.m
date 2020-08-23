function ExcelPrint(prefix,filename,T)

mydir=cd;
if isdir([mydir '/Data'])==0
mkdir('Data')
else
end

newname=strjoin([prefix,'_',filename,'.csv']);
if newname{1}(1)=="_"
    newname=string(newname{1}(2:end));
end
a= [cd,'\Data'];
mydir=cd;
cd(a)

writetable(T,newname,'WriteVariableNames',false);

cd (mydir)
end

