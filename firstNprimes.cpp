// firstNprimes.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <math.h>
#include <stdio.h>

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

int _tmain(int argc, _TCHAR* argv[])
{
	const unsigned int first_N_primes = 200000;
	unsigned int numOfPrimesFound = 0;
	unsigned int aPrimes[first_N_primes] = { 1 };
	unsigned int number;
	unsigned int i;

	printf("first %d primes:", first_N_primes);

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

