// firstNprimes.cpp : Defines the entry point for the console application.
//

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

bool isPrime(const unsigned int number, unsigned int *divisors)
{
	const unsigned int maxDivisor = (unsigned int)sqrt((double) number);
	unsigned int i;

	for (i = 0; divisors[i] <= maxDivisor; i++)
	{
		if (number % divisors[i])
			continue;
		else
			return false;
	}

	return true;
}

int main(int argc, char* argv[])
{
	unsigned int first_N_primes = 10e6;

	if (argc > 1)
	{
		first_N_primes = atoi(argv[1]);
		printf("find %d primes\n", first_N_primes);
		char* str_dec = argv[1];
	}
		
	unsigned int numOfPrimesFound = 0;
	unsigned int* aPrimes = (unsigned int*)malloc(first_N_primes * sizeof(unsigned int));
	if (aPrimes == NULL)
	{
		printf("Not enough memory for %d primes.\n", first_N_primes);
		return -1;
	}

	unsigned int number;
	unsigned int i;

	printf("first %d primes:\n", first_N_primes);

	// evaluate 2 as prime manually
	number = 2;
	aPrimes[numOfPrimesFound++] = number;

	for (number = 3; numOfPrimesFound < first_N_primes; number++)
	{
		if (isPrime(number, aPrimes))
		{
			aPrimes[numOfPrimesFound++] = number;
		}
	}
	
	FILE* fw = fopen("listOfPrimes.txt", "w");

	for (i = 0; i < first_N_primes; i++)
	{
		fprintf(fw, "%d\n", aPrimes[i]);
	}
	
	fclose(fw);

	return 0;
}
