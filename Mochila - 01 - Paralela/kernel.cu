/*Bin Packing - two Dimensional
Problema da mochila com duas dimensoes.
Tal problema consiste em escolher o maior numero de itens que comportem em uma mochila (compartimento)

O dataset osado foi o presente na biblioteca ORLIB (OR-Library)

Cada arquivo contem:
Numero de problemas teste
Identificador do Problema
Capacidade do compartimento, numero de itens, numero de itens presentes na melhor solução conhecida.
Tamanho dos itens.
*/

#define HAVE_STRUCT_TIMESPEC
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include "Objeto.h"
#include "EntradaDeDados.h"
#include "ParallelGRASP.h"
#include "Selection_Sort.h"
#include "SaidaArquivo.h"


typedef struct {
	int max_iter;
	int number_of_itens;
	int bin_capacity;
	item *size_of_itens;
	bool *soluctions;
	int temperatura;
	int decaimento_temperatura;
	int tamanho_RCL;
	int seed;
	int id_thread;
}GRASP_starter;

void* GRASP_thread(void* init)
{
	GRASP_starter arg = *((GRASP_starter* )init);

	//printf("Hello World! It's me, thread with argument %d!\n", (arg).id_thread);

	parallelGRASP((arg).max_iter, (arg).number_of_itens, (arg).bin_capacity, (arg).size_of_itens, (arg).soluctions, (arg).temperatura, (arg).decaimento_temperatura, (arg).tamanho_RCL, (arg).seed, (arg).id_thread);

	return NULL;
}

int main() {
	//semente para gerador de numeros aleatorios
	srand(time(NULL));
	int seed = rand();

	//temperatura inicial e o decaimento da temperatura para SA
	int temperatura = 100;
	int decaimento_temperatura = 1;

	//tamanha usado para tornar a geração da solução inicial e busca aleatoria, se 1 fica modo guloso
	int tamanho_RCL = 10;

	//numero de iterações que o GRASP fara
	int max_iter = 200;

	//quantidade de threads e blocos
	const int threads = 5;

	// numero de elementos
	int quantidade_itens = 0;

	// capacidade mochia
	int capacidade_mochila = 0;

	/*recebendo entrada, tamanho de cada item*/
	entrada_dados(quantidade_itens, capacidade_mochila);

	/*Vetor usado para guardar peso e valor e se esta ou nao na mochila*/
	item *itens;
	itens = (item *)malloc(quantidade_itens * sizeof(item));

	if (!itens) {
		printf("Sem memoria disponivel! (itens)\n");
		exit(1);
	}

	entrada_dados_vetor(itens, quantidade_itens);

	//ordenando os dados com relação ao valor/peso
	selection_sort(itens, quantidade_itens);

	//for (int i = 0; i < quantidade_itens; i++) {
	//	printf("%d %d\n", itens[i].peso, itens[i].valor);
	//}

	//system("pause");

	printf("====== Bin Packing - Bi Dimensional ======\n");
	printf("\n");
	printf("              IFMG - Formiga            \n");
	printf(" Desenvolvido por: Ronan Nunes Campos   \n");
	printf(" Matricula: 0011919                     \n");
	printf("\n");
	printf(" Dados do problema           \n\n");
	printf(" Numero de Itens: %d                    \n", quantidade_itens);
	printf(" Capacidade Mochila: %d                 \n", capacidade_mochila);
	printf(" Numero de Threads: %d                   \n", threads);
	printf(" Numero de Iterações: %d                \n", max_iter);
	printf(" Geradas %d solucões\n", threads * max_iter);
	printf(" Rodando na CPU                          \n");
	printf("===========================================\n");

	//vetor para guardar o id dos elementos presentes na suloção
	bool *soluctions;
	soluctions = (bool *)malloc(quantidade_itens * threads * sizeof(bool));

	if (!soluctions) {
		printf("Sem memoria disponivel! (soluctions)\n");
		exit(1);
	}
	//iniciando a solução com todos os itens fora da mochila == 0
	for (int i = 0; i < quantidade_itens * threads; i++) {
		soluctions[i] = 0;
	}

	// Rodando GRASP em paralelo.
	clock_t t0, tf;
	double tempo_gasto;
	int max_valor = 0; int valor = 0; int cont = 0; int aux_id = 0; int cont_id = 0;
	
	pthread_t thread[threads];
	GRASP_starter arg[threads];
	saida_header();

	//for n vezes para executar testes
	for (int k = 0; k < 100; k++) {
		t0 = clock();
		for (int i = 0; i < threads; i++) {
			arg[i] = { max_iter, quantidade_itens, capacidade_mochila, itens, soluctions, temperatura, decaimento_temperatura, tamanho_RCL, seed, i };
			//printf("In main: creating thread %d\n", i);
			int result_code = pthread_create(&thread[i], NULL, GRASP_thread, (void *)&arg[i]);
			assert(0 == result_code);
		}
		for (int i = 0; i < threads; i++) {
			int result_code = pthread_join(thread[i], NULL);
			assert(0 == result_code);
		}
		for (int i = 0; i < quantidade_itens * threads; i++) {

			if (cont < quantidade_itens) {
				if (soluctions[i] == 1) {
					valor += itens[cont].valor;
				}
				cont++;
			}

			if (cont == quantidade_itens) {

				if (valor > max_valor) {
					max_valor = valor;
					aux_id = cont_id;
				}
				cont_id++;

				cont = 0; valor = 0;
			}
		}
		tf = clock();

		tempo_gasto = ((double)(tf - t0)) / CLOCKS_PER_SEC;
		saida_body(max_valor, tempo_gasto, max_iter, threads);
		printf("\n");
		printf("Tempo total gasto: %lf s\n", tempo_gasto);

		printf("===========================================\n\n");
		printf("max valor: %d\n", max_valor);
		for (int i = quantidade_itens * aux_id; i < quantidade_itens * (aux_id + 1); i++) {
			printf("%d ", soluctions[i]);
		}

		printf("\n");
		printf("fim :)\n\n");
	}
	
	free(itens);
	free(soluctions);
	system("pause");
	return 0;
}