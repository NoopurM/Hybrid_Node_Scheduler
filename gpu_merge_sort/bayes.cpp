#include <iostream>
#include <vector>
#include <fstream>
using namespace std;

#define TRAINING_FILE "training.data"
vector<vector<string>> training_data;

vector<string> split(string phrase, string delimiter){
    vector<string> list;
    string s = string(phrase);
    size_t pos = 0;
    string token;
    while ((pos = s.find(delimiter)) != string::npos) {
        token = s.substr(0, pos);
        list.push_back(token);
        s.erase(0, pos + delimiter.length());
    }
    list.push_back(s);
    return list;
}

void __get_training_data() {
    ifstream file(TRAINING_FILE);
    string line="";
    
    while (getline(file, line))
    {
        vector<string> vec;
        vec = split(line, ",");
        training_data.push_back(vec);
    }
    file.close();
}

void print_training_data() {
    for(vector<string> vec : training_data)
    {
        for(string data : vec)
        {
            cout<<data<<" ";
        }
        cout<<endl;
    }
}

void get_nc_count(vector<string> training, vector<string> testing, float& type_nc, float& size_nc, float& ratio_nc) {
    if (training[0].find(testing[0]) != string::npos) {
        type_nc++;
    }
    if (training[1] == testing[1]) {
        size_nc++;
    }
    if (training[2] == testing[2]) {
        ratio_nc++;
    }
}
void naive_bayes(vector<string> testing_data) {
    float n_cpu, type_nc_cpu, n_gpu, type_nc_gpu, size_nc_cpu, size_nc_gpu, ratio_nc_cpu, ratio_nc_gpu; 
    float p = 0.5, m =3;
    for (int i=0;i<training_data.size();i++) {
        if (training_data[i][3].find("CPU") != string::npos) {
            n_cpu++;
            get_nc_count(training_data[i], testing_data, type_nc_cpu, size_nc_cpu, ratio_nc_cpu);
        } else {
            n_gpu++;
            get_nc_count(training_data[i], testing_data, type_nc_gpu, size_nc_gpu, ratio_nc_gpu);
        }
    }
    
    cout<<"n_cpu = "<<n_cpu<<" n_gpu = "<<n_gpu<<endl;
    cout<<"type_nc_cpu = "<<type_nc_cpu<<" type_nc_gpu = "<<type_nc_gpu<<endl;
    cout<<"size_nc_cpu = "<<size_nc_cpu<<" size_nc_gpu = "<<size_nc_gpu<<endl;
    cout<<"ratio_nc_cpu = "<<ratio_nc_cpu<<" ratio_nc_gpu = "<<ratio_nc_gpu<<endl;
    float p_type_cpu, p_size_cpu, p_ratio_cpu;
    p_type_cpu = ((type_nc_cpu + m*p)/(n_cpu+m));
    p_size_cpu = ((size_nc_cpu + m*p)/(n_cpu+m));
    p_ratio_cpu = ((ratio_nc_cpu + m*p)/(n_cpu+m));
    
    float p_type_gpu, p_size_gpu, p_ratio_gpu;
    p_type_gpu = ((type_nc_gpu + m*p)/(n_gpu+m));
    p_size_gpu = ((size_nc_gpu + m*p)/(n_gpu+m));
    p_ratio_gpu = ((ratio_nc_gpu + m*p)/(n_gpu+m));

    float cpu, gpu;
    cpu = 0.5 * p_type_cpu * p_size_cpu * p_ratio_cpu;
    gpu = 0.5 * p_type_gpu * p_size_gpu * p_ratio_gpu;
    cout<<"CPU :"<<cpu<<" GPU :"<<gpu<<endl;
}
int main() {
    __get_training_data();
    print_training_data();    
     
    vector<string> testing_data = {"merge_sort", "64", "2"};
    naive_bayes(testing_data); 
}
