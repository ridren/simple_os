#include <iostream>
#include <fstream>

#include <string>

int main(int argc, char* argv[])
{
	if(argc < 2)
	{
		std::cout << "Not enough arguments\n";
		return 1;
	}
	std::ifstream read(argv[1]);
	
	if(!read.is_open())
	{
		std::cout << "Error opening file\n";
		return 2;
	}
	std::ofstream write("font8x16.txt");

	int c = 0; 
	std::string line;
	while(std::getline(read, line))
	{
		if(line[0] != 'S' 
		|| line[1] != 'T'
		|| line[5] != 'C') 
			continue;
		if(c >= 128)
			break;

		write << "; 0x" << std::hex << c << '\n';
		c++;	
		//ignore 5 lines
		std::getline(read, line);
		std::getline(read, line);
		std::getline(read, line);
		std::getline(read, line);
		std::getline(read, line);

		std::string text;
		int i = 0;
		while(std::getline(read, line))
		{
			if(line[0] == 'E'
			&& line[1] == 'N')
				break;

			i++;
			std::string to_add = "\tdb 0xXX\n";
			to_add[6] = line[0];
			to_add[7] = line[1];
			text += to_add;
		}
		const int left_to_add = 15 - i;
		for(int j = 0; j < left_to_add; j++)
			write << "\tdb 0x00\n";
		
		write << text;
		
		if(i != 16)
			write << "\tdb 0x00\n";


		//for(; i < 16; i++)
		//	write << "\tdb 0x00\n";
	}


	return 0;
}
