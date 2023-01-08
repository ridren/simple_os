#include <iostream>
#include <cstdlib>
#include <fstream>

#include <string>


int main(int argc, char* argv[])
{
	if(argc < 5)
	{
		std::cout << "Not enough arguments\n";
		return 1;
	}
	FILE* read = fopen(argv[1], "r");

	if(nullptr == read)
	{
		std::cout << "Error opening file\n";
		return 1;
	}

	std::ofstream writer("imgr.txt");
	std::ofstream writeg("imgg.txt");
	std::ofstream writeb("imgb.txt");

	//ignore 2 bytes
	fgetc(read);
	fgetc(read);

	int size = 0;
	size += fgetc(read) << 0x00;
	size += fgetc(read) << 0x08;
	size += fgetc(read) << 0x10;
	size += fgetc(read) << 0x18;
	
	//ignore 4 bytes
	fgetc(read);
	fgetc(read);
	fgetc(read);
	fgetc(read);

	int offset = 0;
	offset += fgetc(read) << 0x00;
	offset += fgetc(read) << 0x08;
	offset += fgetc(read) << 0x10;
	offset += fgetc(read) << 0x18;

	std::cout << "SIZE:   " << size << '\n';
	std::cout << "OFFSET: " << offset << '\n';

	offset -= 14;

	for(int i = 0; i < offset; i++)
		fgetc(read);

	size -= (offset + 14);
	writer << "db ";
	writeg << "db ";
	writeb << "db ";
	int vals[3]; vals[0] = 0; vals[1] = 0; vals[2] = 0;
	int bits = 0;
	const int tresholdr = std::atoi(argv[2]);
	const int tresholdg = std::atoi(argv[3]);
	const int tresholdb = std::atoi(argv[4]);
	for(int i = 0; i < size; i++)
	{
		const int b = fgetc(read);
		const int g = fgetc(read);
		const int r = fgetc(read);

		vals[0] <<= 1;
		vals[0] += (r >= tresholdr);
		vals[1] <<= 1;
		vals[1] += (g >= tresholdg);
		vals[2] <<= 1;
		vals[2] += (b >= tresholdb);

		bits++;
		if(bits == 8)
		{
			writer << vals[0] << ", ";
			writeg << vals[1] << ", ";
			writeb << vals[2] << ", ";
			bits = 0;
			vals[0] = 0;
			vals[1] = 0;
			vals[2] = 0;
		}

	}
	writer << '\n';
	writeg << '\n';
	writeb << '\n';

	return 0;
}

