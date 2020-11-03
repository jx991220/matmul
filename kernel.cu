#include <stdio.h>
#include <stdlib.h>
//CUDA RunTime API
#include <cuda_runtime.h>
using namespace std;
#define THREAD_NUM 1024
#define MATRIX_SIZE 2000

//定义线程块的个数（向上取整）
const int blocks_num = (MATRIX_SIZE * MATRIX_SIZE + THREAD_NUM - 1) / THREAD_NUM;

//CUDA 初始化
bool InitCUDA()
{
    int count;

    //取得支持Cuda的装置的数目
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

//矩阵初始化
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

// __global__ 函数 并行计算矩阵乘法
__global__ static void matMultCUDA(const int* a, const int* b, int* c, int n)
{
    //表示目前的 thread 是第几个 thread（由 0 开始计算）
    const int tid = threadIdx.x;

    //表示目前的 thread 属于第几个 block（由 0 开始计算）
    const int bid = blockIdx.x;

    //从 bid 和 tid 计算出这个 thread 应该计算的 row 和 column
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

// 主函数
int main()
{
    //CUDA 初始化
    if (!InitCUDA()) return 0;

    //定义矩阵
    int* a, * b, * c;
    int n = MATRIX_SIZE;

    //分配内存
    a = (int*)malloc(sizeof(int) * n * n);
    b = (int*)malloc(sizeof(int) * n * n);
    c = (int*)malloc(sizeof(int) * n * n);

    //生成矩阵
    matgen(a, n);
    matgen(b, n);

    /*把数据复制到显卡内存中*/
    int* cuda_a, * cuda_b, * cuda_c;

    //cudaMalloc 取得一块显卡内存 
    cudaMalloc((void**)&cuda_a, sizeof(int) * n * n);
    cudaMalloc((void**)&cuda_b, sizeof(int) * n * n);
    cudaMalloc((void**)&cuda_c, sizeof(int) * n * n);

    //cudaMemcpy 将产生的矩阵复制到显卡内存中
    //cudaMemcpyHostToDevice - 从内存复制到显卡内存
    //cudaMemcpyDeviceToHost - 从显卡内存复制到内存
    cudaMemcpy(cuda_a, a, sizeof(int) * n * n, cudaMemcpyHostToDevice);
    cudaMemcpy(cuda_b, b, sizeof(int) * n * n, cudaMemcpyHostToDevice);

    // 计时
    cudaEvent_t gpuStart, gpuFinish;
    float elapsedTime;
    cudaEventCreate(&gpuStart);
    cudaEventCreate(&gpuFinish);
    cudaEventRecord(gpuStart, 0);

    // 在CUDA 中执行函数 语法：函数名称<<<block 数目, thread 数目, shared memory 大小>>>(参数...);
    matMultCUDA << < blocks_num, THREAD_NUM, 0 >> > (cuda_a, cuda_b, cuda_c, n);
    cudaEventRecord(gpuFinish, 0);
    cudaEventSynchronize(gpuStart);
    cudaEventSynchronize(gpuFinish);
    cudaEventElapsedTime(&elapsedTime, gpuStart, gpuFinish);
    printf("\nThe runing time of GPU on Mat Multiply is %f seconds.\n", elapsedTime / 1000.0);

    //cudaMemcpy 将结果从显存中复制回内存
    cudaMemcpy(c, cuda_c, sizeof(int) * n * n, cudaMemcpyDeviceToHost);

    cudaFree(cuda_a);
    cudaFree(cuda_b);
    cudaFree(cuda_c);
    return 0;
}