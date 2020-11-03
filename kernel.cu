#include <stdio.h>
#include <stdlib.h>
//CUDA RunTime API
#include <cuda_runtime.h>
using namespace std;
#define THREAD_NUM 1024
#define MATRIX_SIZE 2000

//�����߳̿�ĸ���������ȡ����
const int blocks_num = (MATRIX_SIZE * MATRIX_SIZE + THREAD_NUM - 1) / THREAD_NUM;

//CUDA ��ʼ��
bool InitCUDA()
{
    int count;

    //ȡ��֧��Cuda��װ�õ���Ŀ
    cudaGetDeviceCount(&count);
    if (count == 0)
    {
        fprintf(stderr, "There is no device.\n");

        return false;
    }
    int i;
    for (i = 0; i < count; i++)
    {
        cudaDeviceProp prop;
        cudaGetDeviceProperties(&prop, i);
        if (cudaGetDeviceProperties(&prop, i) == cudaSuccess)
        {
            if (prop.major >= 1)
            {
                break;
            }
        }
    }
    if (i == count)
    {
        fprintf(stderr, "There is no device supporting CUDA 1.x.\n");
        return false;
    }
    cudaSetDevice(i);
    return true;
}

//�����ʼ��
void matgen(int* a, int n)
{
    int i, j;
    for (i = 0; i < n; i++)
    {
        for (j = 0; j < n; j++)
        {
            a[i * n + j] = i + j;
        }
    }
}

// __global__ ���� ���м������˷�
__global__ static void matMultCUDA(const int* a, const int* b, int* c, int n)
{
    //��ʾĿǰ�� thread �ǵڼ��� thread���� 0 ��ʼ���㣩
    const int tid = threadIdx.x;

    //��ʾĿǰ�� thread ���ڵڼ��� block���� 0 ��ʼ���㣩
    const int bid = blockIdx.x;

    //�� bid �� tid �������� thread Ӧ�ü���� row �� column
    const int idx = bid * THREAD_NUM + tid;
    const int row = idx / n;
    const int column = idx % n;
    int i;
    if (row < n && column < n)
    {
        int t = 0;
        for (i = 0; i < n; i++)
        {
            t += a[row * n + i] * b[i * n + column];
        }
        c[row * n + column] = t;
    }
}

// ������
int main()
{
    //CUDA ��ʼ��
    if (!InitCUDA()) return 0;

    //�������
    int* a, * b, * c;
    int n = MATRIX_SIZE;

    //�����ڴ�
    a = (int*)malloc(sizeof(int) * n * n);
    b = (int*)malloc(sizeof(int) * n * n);
    c = (int*)malloc(sizeof(int) * n * n);

    //���ɾ���
    matgen(a, n);
    matgen(b, n);

    /*�����ݸ��Ƶ��Կ��ڴ���*/
    int* cuda_a, * cuda_b, * cuda_c;

    //cudaMalloc ȡ��һ���Կ��ڴ� 
    cudaMalloc((void**)&cuda_a, sizeof(int) * n * n);
    cudaMalloc((void**)&cuda_b, sizeof(int) * n * n);
    cudaMalloc((void**)&cuda_c, sizeof(int) * n * n);

    //cudaMemcpy �������ľ����Ƶ��Կ��ڴ���
    //cudaMemcpyHostToDevice - ���ڴ渴�Ƶ��Կ��ڴ�
    //cudaMemcpyDeviceToHost - ���Կ��ڴ渴�Ƶ��ڴ�
    cudaMemcpy(cuda_a, a, sizeof(int) * n * n, cudaMemcpyHostToDevice);
    cudaMemcpy(cuda_b, b, sizeof(int) * n * n, cudaMemcpyHostToDevice);

    // ��ʱ
    cudaEvent_t gpuStart, gpuFinish;
    float elapsedTime;
    cudaEventCreate(&gpuStart);
    cudaEventCreate(&gpuFinish);
    cudaEventRecord(gpuStart, 0);

    // ��CUDA ��ִ�к��� �﷨����������<<<block ��Ŀ, thread ��Ŀ, shared memory ��С>>>(����...);
    matMultCUDA << < blocks_num, THREAD_NUM, 0 >> > (cuda_a, cuda_b, cuda_c, n);
    cudaEventRecord(gpuFinish, 0);
    cudaEventSynchronize(gpuStart);
    cudaEventSynchronize(gpuFinish);
    cudaEventElapsedTime(&elapsedTime, gpuStart, gpuFinish);
    printf("\nThe runing time of GPU on Mat Multiply is %f seconds.\n", elapsedTime / 1000.0);

    //cudaMemcpy ��������Դ��и��ƻ��ڴ�
    cudaMemcpy(c, cuda_c, sizeof(int) * n * n, cudaMemcpyDeviceToHost);

    cudaFree(cuda_a);
    cudaFree(cuda_b);
    cudaFree(cuda_c);
    return 0;
}