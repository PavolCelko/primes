// firstNprimes.cpp : Defines the entry point for the console application.
//
//#include "stdafx.h"
#include <math.h>
#include <stdio.h>
#include <string>

// For the CUDA runtime routines (prefixed with "cuda_")
#include <cuda_runtime.h>

#define TWO				2
#define FIRST_PRIME		TWO

typedef struct
{

}primesClass_t;

__global__
void isPrime(const unsigned int number, const unsigned int *divisors, const unsigned int maxDivisor, unsigned long int *results)
{
	int index = blockIdx.x * blockDim.x + threadIdx.x;
	// int stride = blockDim.x * gridDim.x;
	// int i;

	__syncthreads();

	results[index] = number % divisors[index];

	// for (i = index; divisors[i] <= maxDivisor; i += stride)
	// {
	// 	results[i] = number % divisors[i];
		
	// 	if (number % divisors[i])
	// 		continue;
	// 	else
	// 		break;
	// }

	__syncthreads();

	//return true;
	//results[i] = true;
}

void syncPrimes(const unsigned int *h_aPrimes, unsigned int *d_aPrimes, 
	const unsigned int *h_pNumOfPrimesFound, unsigned int *h_pNumOfPrimesFoundOnGPU)
{
	cudaError_t err;
	
	// printf("h_pNumOfPrimesFound = %d\n", *h_pNumOfPrimesFound);
	// printf("h_pNumOfPrimesFoundOnGPU = %d\n", *h_pNumOfPrimesFoundOnGPU);

	err = cudaMemcpy(&d_aPrimes[*h_pNumOfPrimesFoundOnGPU], &h_aPrimes[*h_pNumOfPrimesFoundOnGPU], 
		(*h_pNumOfPrimesFound - *h_pNumOfPrimesFoundOnGPU)*sizeof(unsigned int), cudaMemcpyHostToDevice);
	if (err != cudaSuccess)
	{
        fprintf(stderr, "Sync primes failed (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
	}
	else
	{
		*h_pNumOfPrimesFoundOnGPU = *h_pNumOfPrimesFound;
		printf("GPU primes array synced\n");
	}
}

bool find_N_primes(const unsigned int N, unsigned int *h_aPrimes, unsigned long int uSize, unsigned int *h_pNumOfPrimesFound)
{
	unsigned int number;
	unsigned int maxDivisor;
	unsigned int *d_aPrimes = NULL;
	unsigned int *h_aPrimesTempHelp = NULL;
	unsigned int h_numOfPrimesFoundOnGPU = 0;

	cudaError_t err;

	err = cudaMalloc((void **)&d_aPrimes, uSize);
	if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to allocate GPU memory for primes array (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
	}
	h_aPrimesTempHelp = (unsigned int *)malloc(uSize);
	if(h_aPrimesTempHelp == NULL)
	{
		printf("Failed to allocate h_aPrimesTempHelp\n");
        exit(EXIT_FAILURE);
	}
	// printf("GPU primes array allocated\n");
	err = cudaMemcpy(d_aPrimes, h_aPrimes, uSize, cudaMemcpyHostToDevice);
	if (err != cudaSuccess)
	{
        fprintf(stderr, "Failed to copy array to GPU (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
	}
	printf("GPU primes array allocated\n");
		
	unsigned long int* d_results = NULL;
	err = cudaMalloc((void **)&d_results, uSize);
	if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to allocate GPU memory for d_results (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
	}
	unsigned long int *h_pResults = (unsigned long int*)malloc(uSize);
	printf("GPU d_results allocated\n");

	int i, maxDivisorIndex;

	for (number = 3; *h_pNumOfPrimesFound < N; number++)
	{
		maxDivisor = (int)sqrt((double) number);
		for(maxDivisorIndex = 0; h_aPrimes[maxDivisorIndex] < maxDivisor; maxDivisorIndex++);
		// printf("h_pNumOfPrimesFound = %d\n", *h_pNumOfPrimesFound);
		if(number == 121)
		{
			printf("maxDivisor %d\n", maxDivisor);
			printf("maxDivisorIndex %d\n", maxDivisorIndex);
			printf("h_aPrimes[maxDivisorIndex] %u\n", h_aPrimes[maxDivisorIndex]);
			printf("h_numOfPrimesFoundOnGPU = %u\n", h_numOfPrimesFoundOnGPU);
			printf("*h_pNumOfPrimesFound = %u\n", *h_pNumOfPrimesFound);
			printf("h_aPrimes[h_numOfPrimesFoundOnGPU] %u\n", h_aPrimes[h_numOfPrimesFoundOnGPU]);
			cudaDeviceSynchronize();
			err = cudaMemcpy((void *)h_aPrimesTempHelp, (void *)d_aPrimes, 5*sizeof(unsigned int), cudaMemcpyDeviceToHost);
			for (i = 0; i < h_numOfPrimesFoundOnGPU; i++)
				printf("sync d_aPrimes[%d] = %u\n", i, h_aPrimesTempHelp[i]);
		}
		if (maxDivisor > h_aPrimes[h_numOfPrimesFoundOnGPU])
			syncPrimes(h_aPrimes, d_aPrimes, h_pNumOfPrimesFound, &h_numOfPrimesFoundOnGPU);
		
		isPrime<<<1, 1024>>>(number, d_aPrimes, maxDivisor, d_results);
		cudaDeviceSynchronize();
		err = cudaMemcpy(h_pResults, d_results, uSize, cudaMemcpyDeviceToHost);
		for(i = 0; i <= maxDivisorIndex; i++)
		{			
			
			if(number == 121)
			{	
				printf("h_aPrimesTempHelp[%d] = %u\n", i, h_aPrimesTempHelp[i]);
				printf("h_pResults[%d] = %ld\n", i, h_pResults[i]);				
			}
			if(h_pResults[i] == 0)
				break;
		}
		if (i == maxDivisorIndex + 1)
		{
			printf("PRIME FOUND = %d\n", number);
			h_aPrimes[(*h_pNumOfPrimesFound)++] = number;
		}					
	}

	// err = cudaMemcpy(h_aPrimes, d_aPrimes, uSize, cudaMemcpyDeviceToHost);
	// if (err != cudaSuccess)
	// {
    //     fprintf(stderr, "Failed to copy calculated primes from GPU to host (error code %s)!\n", cudaGetErrorString(err));
    //     exit(EXIT_FAILURE);
	// }
	
	cudaFree(d_results);
	cudaFree(d_aPrimes);
	free(h_aPrimesTempHelp);

	return true;
}


//int _tmain(int argc, _TCHAR* argv[])
int main(int argc, char* argv[])
{
	// printf("argc: %d\n", argc);
	// int i_dec = 0;
	// std::string::size_type sz;   // alias of size_t
	
	unsigned int uiFirst_N_primes = 10e2;
	
	if (argc > 1)
	{
		uiFirst_N_primes = atoi(argv[1]);		
		//char* str_dec = argv[1];
	}
	printf("find %d primes\n", uiFirst_N_primes);
	unsigned long int ulSize = uiFirst_N_primes * sizeof(unsigned int);
	printf("size = %lu\n", ulSize);
	unsigned int h_numOfPrimesFound = 0;
	unsigned int* h_aPrimes = (unsigned int*)malloc(ulSize);
	if (h_aPrimes == NULL)
	{
		printf("Not enough memory for %d primes.\n", uiFirst_N_primes);
		exit(EXIT_FAILURE);
	}
	memset(h_aPrimes, 1U, ulSize);		

	// evaluate 2 as prime manually
	h_aPrimes[h_numOfPrimesFound++] = FIRST_PRIME;
	
	find_N_primes(uiFirst_N_primes, h_aPrimes, ulSize, &h_numOfPrimesFound);
	
	FILE* fw = fopen("cudaListOfPrimes.txt", "w");
	unsigned int i;

	for (i = 0; i < uiFirst_N_primes; i++)
	{
		fprintf(fw, "%d\n", h_aPrimes[i]);
	}
	
	fclose(fw);
	free(h_aPrimes);

	return 0;
}

