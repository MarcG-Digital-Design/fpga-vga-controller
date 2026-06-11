% bmp_to_mif.m
% Converts a 256x256 BMP image to a 12-bit MIF file for Intel Quartus ROM.
% Each word encodes one pixel as RRRR_GGGG_BBBB (4 bits per channel).
%
% Usage:
%   bmp_to_mif('input.bmp', '../mif/image.mif')

function bmp_to_mif(input_bmp, output_mif)

    if nargin < 1, input_bmp  = 'input.bmp';       end
    if nargin < 2, output_mif = '../mif/image.mif'; end

    img = imread(input_bmp);

    [h, w, ch] = size(img);
    assert(h == 256 && w == 256 && ch == 3, ...
        'Image must be 256x256 RGB.');

    % Quantise 8-bit channels down to 4 bits
    r4 = bitshift(img(:,:,1), -4);
    g4 = bitshift(img(:,:,2), -4);
    b4 = bitshift(img(:,:,3), -4);

    depth  = 256 * 256;   % 65 536 words
    width  = 12;          % bits per word

    fid = fopen(output_mif, 'w');
    fprintf(fid, 'DEPTH = %d;\n', depth);
    fprintf(fid, 'WIDTH = %d;\n', width);
    fprintf(fid, 'ADDRESS_RADIX = HEX;\n');
    fprintf(fid, 'DATA_RADIX = HEX;\n');
    fprintf(fid, 'CONTENT BEGIN\n');

    addr = 0;
    for row = 1:256
        for col = 1:256
            word = bitor(bitor( ...
                bitshift(uint16(r4(row,col)), 8), ...
                bitshift(uint16(g4(row,col)), 4)), ...
                uint16(b4(row,col)));
            fprintf(fid, '\t%04X : %03X;\n', addr, word);
            addr = addr + 1;
        end
    end

    fprintf(fid, 'END;\n');
    fclose(fid);

    fprintf('Done. Written %d words to %s\n', depth, output_mif);
end
