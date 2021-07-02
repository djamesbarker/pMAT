function y = rms(u)
    y = sqrt(sum(u.*conj(u))/max(size(u)));
end