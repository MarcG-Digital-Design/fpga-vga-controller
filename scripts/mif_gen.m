%==========================================================================
% Author : Marc Gruchet
% Description : Converts a 24-bit BMP image into a .mif file (Memory
%               Initialization File) for use in FPGA memory blocks.
%               Each pixel is encoded on 12 bits (4 bits per RGB channel).
%==========================================================================

clear global;
clc;

% Read the image data: three superimposed RGB matrices (24-bit BMP format)
img = imread('PERROQUE_256_256.bmp');

% Extract each color channel matrix
VECTOR_R = img(:,:,1);
VECTOR_G = img(:,:,2);
VECTOR_B = img(:,:,3);

[L,C] = size(VECTOR_R);   % Get number of rows (L) and columns (C)
N = L*C;                  % Total RAM size (number of pixels)
word_len = 12;            % Word size: 12 bits per pixel (4 bits R + 4 bits G + 4 bits B)

% Reshape the matrices into a 1xN vector (linear addressing)
data_R = reshape(VECTOR_R, 1, N);
data_G = reshape(VECTOR_G, 1, N);
data_B = reshape(VECTOR_B, 1, N);

% Convert each channel from 8 bits (0-255) down to 4 bits (0-15).
% We divide by 17 instead of 16 to avoid overflow:
% 255/16 = 15.9375 -> would round up to 16 = b'10000' (5 bits), which exceeds 4 bits.
% 255/17 = 15      -> stays within 4 bits.
data_R = VECTOR_R./17;
data_G = VECTOR_G./17;
data_B = VECTOR_B./17;

% Create / open the output .mif file
fid = fopen('PERROQUET.mif', 'w');

% Write the .mif file header
fprintf(fid, 'DEPTH=%d;\n', N);            % Number of memory words
fprintf(fid, 'WIDTH=%d;\n', word_len);     % Word width in bits
fprintf(fid, 'ADDRESS_RADIX = UNS;\n');    % Addresses in unsigned decimal
fprintf(fid, 'DATA_RADIX = HEX;\n');       % Data values in hexadecimal
fprintf(fid, 'CONTENT\t');
fprintf(fid, 'BEGIN\n');                   % Required .mif syntax

% Write the image data as concatenated RGB hexadecimal values
for i = 0 : N-1
    fprintf(fid, '\t%d\t:\t%x%x%x;\n', i, data_R(i+1), data_G(i+1), data_B(i+1));
end

fprintf(fid, 'END;\n');   % End of .mif file
fclose(fid);              % Close the file