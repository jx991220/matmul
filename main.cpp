#include<iostream>
#include<vector>
#include<string>
#include<algorithm>
#include<thread>
#include<ctime>

using namespace std;

// f mn = d mt * e tn
vector<vector<int> > d;
vector<vector<int> > e;
vector<vector<int> > f;

//single thread
void mulSingle()
{
	int m = d.size();
	int t = d[0].size();
	int n = e[0].size();
	// ikj is faster than ijk (memory access issues)
	for (int i = 0; i < m; ++i)
		for (int k = 0; k < t; ++k)
		{
			int s = d[i][k];
			for (int j = 0; j < n; ++j)
				f[i][j] += s * e[k][j];
		}
}

//multi thread
void mulMulti(int rowStart, int rowEnd)
{
	int m = d.size();
	int t = d[0].size();
	int n = e[0].size();
	// ikj is faster than ijk (memory access issues)
	for (int i = rowStart; i < rowEnd; ++i)
		for (int k = 0; k < t; ++k)
		{
			int s = d[i][k];
			for (int j = 0; j < n; ++j)
				f[i][j] += s * e[k][j];
		}
}
// create a matrix
vector<vector<int> > createMat(int m, int n) {
	vector<vector<int> > ans(m, vector<int>(n, 0));
	for (int i = 0; i < m; i++)
		for (int j = 0; j < n; j++)
			ans[i][j] = i + j;   // arbitrary value
	return ans;
}
int main()
{
	clock_t startTime, endTime;

	// initializing matrices
	d = createMat(2000, 2000);
	e = createMat(2000, 2000);

	// f (m*n) = d (m*t) * e (t*n)
	int m = d.size();
	int t = d[0].size();
	int n = e[0].size();

	f.resize(m);
	for (int i = 0; i < m; ++i)
		f[i].resize(n);

	//single thread
	startTime = clock();
	mulSingle();
	endTime = clock();

	//display

	cout << "Single Thread Total Time : " << (double)(endTime - startTime)\
		/ CLOCKS_PER_SEC << " s" << endl;

	// initializing matrix
	f.clear();
	f.resize(m);
	for (int i = 0; i < m; ++i)
		f[i].resize(n);
	cout << endl;

	//multiple thread
	startTime = clock();
	int div = m / 4;
	thread t1(mulMulti, 0, div);
	thread t2(mulMulti, div, 2 * div);
	thread t3(mulMulti, 2 * div, 3 * div);
	thread t4(mulMulti, 3 * div, m);
	t1.join();
	t2.join();
	t3.join();
	t4.join();
	endTime = clock();

	//display

	cout << "Four Threads Total Time : " << (double)(endTime - startTime)\
		/ CLOCKS_PER_SEC << " s" << endl;
	cout << endl;

	startTime = clock();
	int divv = m / 8;
	thread th1(mulMulti, 0, divv);
	thread th2(mulMulti, divv, 2 * divv);
	thread th3(mulMulti, 2 * divv, 3 * divv);
	thread th4(mulMulti, 3 * divv, 4 * divv);
	thread th5(mulMulti, 4 * divv, 5 * divv);
	thread th6(mulMulti, 5 * divv, 6 * divv);
	thread th7(mulMulti, 6 * divv, 7 * divv);
	thread th8(mulMulti, 7 * divv, 8 * divv);
	th1.join();
	th2.join();
	th3.join();
	th4.join();
	th5.join();
	th6.join();
	th7.join();
	th8.join();
	endTime = clock();

	cout << "Eight Threads Total Time : " << (double)(endTime - startTime)\
		/ CLOCKS_PER_SEC << " s" << endl;

	startTime = clock();
	int divvv = m / 12;
	thread thr1(mulMulti, 0, divvv);
	thread thr2(mulMulti, divvv, 2 * divvv);
	thread thr3(mulMulti, 2 * divvv, 3 * divvv);
	thread thr4(mulMulti, 3 * divvv, 4 * divvv);
	thread thr5(mulMulti, 4 * divvv, 5 * divvv);
	thread thr6(mulMulti, 5 * divvv, 6 * divvv);
	thread thr7(mulMulti, 6 * divvv, 7 * divvv);
	thread thr8(mulMulti, 7 * divvv, 8 * divvv);
	thread thr9(mulMulti, 8 * divvv, 9 * divvv);
	thread thr10(mulMulti, 9 * divvv, 10 * divvv);
	thread thr11(mulMulti, 10 * divvv, 11 * divvv);
	thread thr12(mulMulti, 11 * divvv, m);
	thr1.join();
	thr2.join();
	thr3.join();
	thr4.join();
	thr5.join();
	thr6.join();
	thr7.join();
	thr8.join();
	thr9.join();
	thr10.join();
	thr11.join();
	thr12.join();
	endTime = clock();

	cout << "Twelve Threads Total Time : " << (double)(endTime - startTime)\
		/ CLOCKS_PER_SEC << " s" << endl;
	//this_thread::sleep_for(chrono::seconds(5));
	return 0;
}
