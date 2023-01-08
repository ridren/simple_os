#include <iostream>
#include <fstream>


#include <string>

#include <climits>

#define C0  0
#define CS  1
#define D0  2
#define DS  3
#define E0  4
#define F0  5
#define FS  6
#define G0  7
#define GS  8
#define A0  9
#define AS 10
#define B0 11


int octvals[] = {
//oct0
SHRT_MAX, //1193180 /   16, 
SHRT_MAX, //1193180 /   17,
SHRT_MAX, //1193180 /   18,
1193180 /   19,
1193180 /   20,
1193180 /   21,
1193180 /   23,
1193180 /   24,
1193180 /   25,
1193180 /   27,
1193180 /   29,
1193180 /   30,

//oct1
1193180 /   32,
1193180 /   34,
1193180 /   36,
1193180 /   38,
1193180 /   41,
1193180 /   43,
1193180 /   46,
1193180 /   49,
1193180 /   51,
1193180 /   55,
1193180 /   58,
1193180 /   61,

//oct2
1193180 /   65,
1193180 /   69,
1193180 /   73,
1193180 /   77,
1193180 /   82,
1193180 /   87,
1193180 /   92,
1193180 /   98,
1193180 /  103,
1193180 /  110,
1193180 /  116,
1193180 /  123,

//oct3
1193180 /  130,
1193180 /  138,
1193180 /  146,
1193180 /  155,
1193180 /  164,
1193180 /  174,
1193180 /  185,
1193180 /  196,
1193180 /  207,
1193180 /  220,
1193180 /  233,
1193180 /  246,

//oct4
1193180 /  261,
1193180 /  277,
1193180 /  293,
1193180 /  311,
1193180 /  329,
1193180 /  349,
1193180 /  369,
1193180 /  392,
1193180 /  415,
1193180 /  440,
1193180 /  466,
1193180 /  493,

//oct5 
1193180 /  523,
1193180 /  554,
1193180 /  587,
1193180 /  622,
1193180 /  659,
1193180 /  698,
1193180 /  739,
1193180 /  783,
1193180 /  830,
1193180 /  880,
1193180 /  932,
1193180 /  987,

//oct6
1193180 / 1047,
1193180 / 1108,
1193180 / 1174,
1193180 / 1244,
1193180 / 1318,
1193180 / 1396,
1193180 / 1479,
1193180 / 1567,
1193180 / 1661,
1193180 / 1760,
1193180 / 1864,
1193180 / 1975,

//oct7 
1193180 / 2093,
1193180 / 2217,
1193180 / 2349,
1193180 / 2489,
1193180 / 2637,
1193180 / 2793,
1193180 / 2959,
1193180 / 3135,
1193180 / 3322,
1193180 / 3520,
1193180 / 3729,
1193180 / 3951,

//oct8
1193180 / 4186,
1193180 / 4434,
1193180 / 4698,
1193180 / 4978,
1193180 / 5274,
1193180 / 5587,
1193180 / 5919,
1193180 / 6271,
1193180 / 6644,
1193180 / 7040,
1193180 / 7458,
1193180 / 7902
};
 	
int main(int argc, char* argv[])
{
	if(argc < 2)
	{
		std::cout << "Not enough arguments\n";
		return 1;
	}

	std::ifstream read(argv[1]);
	std::ofstream write("music.txt");

	std::string oct8 = "8|--------------------------|";
	std::string oct7 = "7|--------------------------|";
	std::string oct6 = "6|--------------------------|";
	std::string oct5 = "5|--------------------------|";
	std::string oct4 = "4|--------------------------|";
	std::string oct3 = "3|--------------------------|";
	std::string oct2 = "2|--------------------------|";
	std::string oct1 = "1|--------------------------|";
	std::string oct0 = "0|--------------------------|";
	std::string line;
	int last = 0;
	while(std::getline(read, line))
	{
		if(line.size() != 0)
		{
			switch(line[0])
			{
			case '0':
				oct0 = line;
				break;
			case '1':
				oct1 = line;
				break;
			case '2':
				oct2 = line;
				break;
			case '3':
				oct3 = line;
				break;
			case '4':
				oct4 = line;
				break;
			case '5':
				oct5 = line;
				break;
			case '6':
				oct6 = line;
				break;
			case '7':
				oct7 = line;
				break;
			case '8':
				oct8 = line;
				break;

			}
	
			continue;
		}

		write << "dw ";
		for(int i = 2; i < oct8.size() - 1; i++)
		{
		check_oct8:
			switch(oct8[i])
			{
			case '-':
				goto check_oct7;
			case 'a':
				last = A0 + 8 * 12;
				break;
			case 'b':
				last = B0 + 8 * 12;
				break;
			case 'c':
				last = C0 + 8 * 12;
				break;
			case 'd':
				last = D0 + 8 * 12;
				break;
			case 'e':
				last = E0 + 8 * 12;
				break;
			case 'f':
				last = F0 + 8 * 12;
				break;
			case 'g':
				last = G0 + 8 * 12;
				break;
			case 'A':
				last = AS + 8 * 12;
				break;
			case 'C':
				last = CS + 8 * 12;
				break;
			case 'D':
				last = DS + 8 * 12;
				break;
			case 'F':
				last = FS + 8 * 12;
				break;
			case 'G':
				last = GS + 8 * 12;
				break;
			}
			write << octvals[last] << ", ";
			continue;
		check_oct7:
			switch(oct7[i])
			{
			case '-':
				goto check_oct6;
			case 'a':
				last = A0 + 7 * 12;
				break;
			case 'b':
				last = B0 + 7 * 12;
				break;
			case 'c':
				last = C0 + 7 * 12;
				break;
			case 'd':
				last = D0 + 7 * 12;
				break;
			case 'e':
				last = E0 + 7 * 12;
				break;
			case 'f':
				last = F0 + 7 * 12;
				break;
			case 'g':
				last = G0 + 7 * 12;
				break;
			case 'A':
				last = AS + 7 * 12;
				break;
			case 'C':
				last = CS + 7 * 12;
				break;
			case 'D':
				last = DS + 7 * 12;
				break;
			case 'F':
				last = FS + 7 * 12;
				break;
			case 'G':
				last = GS + 7 * 12;
				break;
			}
			write << octvals[last] << ", ";
			continue;
		check_oct6:
			switch(oct6[i])
			{
			case '-':
				goto check_oct5;
			case 'a':
				last = A0 + 6 * 12;
				break;
			case 'b':
				last = B0 + 6 * 12;
				break;
			case 'c':
				last = C0 + 6 * 12;
				break;
			case 'd':
				last = D0 + 6 * 12;
				break;
			case 'e':
				last = E0 + 6 * 12;
				break;
			case 'f':
				last = F0 + 6 * 12;
				break;
			case 'g':
				last = G0 + 6 * 12;
				break;
			case 'A':
				last = AS + 6 * 12;
				break;
			case 'C':
				last = CS + 6 * 12;
				break;
			case 'D':
				last = DS + 6 * 12;
				break;
			case 'F':
				last = FS + 6 * 12;
				break;
			case 'G':
				last = GS + 6 * 12;
				break;
			}
			write << octvals[last] << ", ";
			continue;
		check_oct5:
			switch(oct5[i])
			{
			case '-':
				goto check_oct4;
			case 'a':
				last = A0 + 5 * 12;
				break;
			case 'b':
				last = B0 + 5 * 12;
				break;
			case 'c':
				last = C0 + 5 * 12;
				break;
			case 'd':
				last = D0 + 5 * 12;
				break;
			case 'e':
				last = E0 + 5 * 12;
				break;
			case 'f':
				last = F0 + 5 * 12;
				break;
			case 'g':
				last = G0 + 5 * 12;
				break;
			case 'A':
				last = AS + 5 * 12;
				break;
			case 'C':
				last = CS + 5 * 12;
				break;
			case 'D':
				last = DS + 5 * 12;
				break;
			case 'F':
				last = FS + 5 * 12;
				break;
			case 'G':
				last = GS + 5 * 12;
				break;
			}
			write << octvals[last] << ", ";
			continue;
		check_oct4:
			switch(oct4[i])
			{
			case '-':
				goto check_oct3;
			case 'a':
				last = A0 + 4 * 12;
				break;
			case 'b':
				last = B0 + 4 * 12;
				break;
			case 'c':
				last = C0 + 4 * 12;
				break;
			case 'd':
				last = D0 + 4 * 12;
				break;
			case 'e':
				last = E0 + 4 * 12;
				break;
			case 'f':
				last = F0 + 4 * 12;
				break;
			case 'g':
				last = G0 + 4 * 12;
				break;
			case 'A':
				last = AS + 4 * 12;
				break;
			case 'C':
				last = CS + 4 * 12;
				break;
			case 'D':
				last = DS + 4 * 12;
				break;
			case 'F':
				last = FS + 4 * 12;
				break;
			case 'G':
				last = GS + 4 * 12;
				break;
			}
			write << octvals[last] << ", ";
			continue;
		check_oct3:
			switch(oct3[i])
			{
			case '-':
				goto check_oct2;
			case 'a':
				last = A0 + 3 * 12;
				break;
			case 'b':
				last = B0 + 3 * 12;
				break;
			case 'c':
				last = C0 + 3 * 12;
				break;
			case 'd':
				last = D0 + 3 * 12;
				break;
			case 'e':
				last = E0 + 3 * 12;
				break;
			case 'f':
				last = F0 + 3 * 12;
				break;
			case 'g':
				last = G0 + 3 * 12;
				break;
			case 'A':
				last = AS + 3 * 12;
				break;
			case 'C':
				last = CS + 3 * 12;
				break;
			case 'D':
				last = DS + 3 * 12;
				break;
			case 'F':
				last = FS + 3 * 12;
				break;
			case 'G':
				last = GS + 3 * 12;
				break;
			}
			write << octvals[last] << ", ";
			continue;
		check_oct2:
			switch(oct2[i])
			{
			case '-':
				goto check_oct1;
			case 'a':
				last = A0 + 2 * 12;
				break;
			case 'b':
				last = B0 + 2 * 12;
				break;
			case 'c':
				last = C0 + 2 * 12;
				break;
			case 'd':
				last = D0 + 2 * 12;
				break;
			case 'e':
				last = E0 + 2 * 12;
				break;
			case 'f':
				last = F0 + 2 * 12;
				break;
			case 'g':
				last = G0 + 2 * 12;
				break;
			case 'A':
				last = AS + 2 * 12;
				break;
			case 'C':
				last = CS + 2 * 12;
				break;
			case 'D':
				last = DS + 2 * 12;
				break;
			case 'F':
				last = FS + 2 * 12;
				break;
			case 'G':
				last = GS + 2 * 12;
				break;
			}
			write << octvals[last] << ", ";
			continue;
		check_oct1:
			switch(oct1[i])
			{
			case '-':
				goto check_oct0;
			case 'a':
				last = A0 + 1 * 12;
				break;
			case 'b':
				last = B0 + 1 * 12;
				break;
			case 'c':
				last = C0 + 1 * 12;
				break;
			case 'd':
				last = D0 + 1 * 12;
				break;
			case 'e':
				last = E0 + 1 * 12;
				break;
			case 'f':
				last = F0 + 1 * 12;
				break;
			case 'g':
				last = G0 + 1 * 12;
				break;
			case 'A':
				last = AS + 1 * 12;
				break;
			case 'C':
				last = CS + 1 * 12;
				break;
			case 'D':
				last = DS + 1 * 12;
				break;
			case 'F':
				last = FS + 1 * 12;
				break;
			case 'G':
				last = GS + 1 * 12;
				break;
			}
			write << octvals[last] << ", ";
			continue;
		check_oct0:
			switch(oct0[i])
			{
			case '-':
				break;
			case 'a':
				last = A0;
				break;
			case 'b':
				last = B0;
				break;
			case 'c':
				last = C0;
				break;
			case 'd':
				last = D0;
				break;
			case 'e':
				last = E0;
				break;
			case 'f':
				last = F0;
				break;
			case 'g':
				last = G0;
				break;
			case 'A':
				last = AS;
				break;
			case 'C':
				last = CS;
				break;
			case 'D':
				last = DS;
				break;
			case 'F':
				last = FS;
				break;
			case 'G':
				last = GS;
				break;
			}
			write << octvals[last] << ", ";
			continue;
		}
		write << '\n';
		oct8 = "8|--------------------------|";
		oct7 = "7|--------------------------|";
		oct6 = "6|--------------------------|";
		oct5 = "5|--------------------------|";
		oct4 = "4|--------------------------|";
		oct3 = "3|--------------------------|";
		oct2 = "2|--------------------------|";
		oct1 = "1|--------------------------|";
		oct0 = "0|--------------------------|";
	}


	return 0;
}
