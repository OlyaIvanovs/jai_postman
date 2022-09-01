key_utf32_to_utf8 :: (ch: u32) -> (s: [4]u8, count: int) {
    UNI_MAX_LEGAL_UTF32 :: 0x0010FFFF;
    UNI_REPLACEMENT_CHAR :: 0x0000FFFD;

    count := 0;
    if ch < 0x80                        count = 1;
    else if ch < 0x800                  count = 2;
    else if ch < 0x10000                count = 3;
    else if ch <= UNI_MAX_LEGAL_UTF32   count = 4;
    else {
        count = 3;
        ch = UNI_REPLACEMENT_CHAR;
    }

    s : [4]u8;

    byteMask :: 0xBF;
    byteMark :: 0x80; 

    if count == {
        case 4; s.data[3] = xx (ch | byteMark) & byteMask; ch = ch >> 6; #through;
        case 3; s.data[2] = xx (ch | byteMark) & byteMask; ch = ch >> 6; #through;
        case 2; s.data[1] = xx (ch | byteMark) & byteMask; ch = ch >> 6; #through;
        case 1; s.data[0] = xx (ch | firstByteMark[count]);
    }

    return s, count;
}

trailingBytesForUTF8 :: u8.[
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, 3,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5
];

utf8_inital_byte_mask :: u8.[ 0x7F, 0x1F, 0x0F, 0x07, 0x03, 0x01 ];

offsetsFromUTF8 : [6] u32 : .[ 0x00000000, 0x00003080, 0x000E2080, 
					           0x03C82080, 0xFA082080, 0x82082080 ];

firstByteMark : [7] u8 : .[ 0x00, 0x00, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC ];
