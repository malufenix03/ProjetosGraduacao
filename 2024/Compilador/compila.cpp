/*
nome: 		Luana Rodrigues da Silva e Lima
SO:			Windows
Compilador:	DevC++
*/
#include <bits/stdc++.h>
#include <stdlib.h>
#include <algorithm>

using namespace std;
typedef long long int ll;

FILE *fonte;
FILE *intermediario;

//conjuntos
set <char> letras;
set <char> digitos;
map <string,string> palavras_reservadas;
map <string,string> simbolos_especiais;
map <string,set<string> > psi;

//tabela de simbolos
vector<vector<string>> simbolo;

//variaveis para auxilio
int linha=1;			//linha erro e tabela simbolo
int linhaReal=1;		//linha contando pular linha duas vezes seguidas em comentários
char proximo=' ';		//caractere a analisar
char anterior='a';		//caractere anterior para troca de linha 
int pular_linha=false;
bool fim_arquivo=false;	//salvar informacao antes de fechar programa
string erro;
string certo;

//identificadores
map <string,string> identificadores;	//identificadores criados
int idNum=0;		//numero de identificadores distintos
vector<string> ordem; 	//ordem insercao identificadores

//cabeçalho funcoes
void BLOCO();
void COMANDO_COMPOSTO();
void COMANDO_SEM_ROTULO();
void EXPRESSAO();

void abrir_arquivo(char* nome,char* modo){
	fonte = fopen(nome,modo);
	if(fonte==NULL){
		cout << "Arquivo nao encontrado";
	}
}

void escrever_arquivo(char* a, int tamanho){
	fwrite(a,tamanho,1,intermediario);
}

void escrever_intermediario(){
	intermediario=fopen("Analise_Lexica.txt","w");
	int tam=simbolo.size();
	for(int i=0;i<tam;i++){
		if(!simbolo[i].empty()){
			string l=to_string(i+1);
			l+="\t";
			int nl=l.size();
			char* li=&l[0];
			escrever_arquivo(li,nl);
			for(auto lexema: simbolo[i]){
				char* converte = &lexema[0];
				int n=lexema.size();
				escrever_arquivo(converte,n);
				escrever_arquivo(" ",1);
			}
			escrever_arquivo("\n",1);
		}
	}
	escrever_arquivo("#",1);
	fclose(intermediario);
}


void fechar_arquivo(){
	fclose(fonte);
}

void setarSimbolosCompostos(){
	palavras_reservadas.insert(pair<string,string>("PROGRAM","PROGRAM"));
	palavras_reservadas.insert(pair<string,string>("LABEL","LABEL"));
	palavras_reservadas.insert(pair<string,string>("VAR","VAR"));
	palavras_reservadas.insert(pair<string,string>("PROCEDURE","PROCEDURE"));
	palavras_reservadas.insert(pair<string,string>("FUNCTION","FUNCTION"));
	palavras_reservadas.insert(pair<string,string>("BEGIN","BEGIN"));
	palavras_reservadas.insert(pair<string,string>("END","END"));
	palavras_reservadas.insert(pair<string,string>("IF","IF"));
	palavras_reservadas.insert(pair<string,string>("THEN","THEN"));
	palavras_reservadas.insert(pair<string,string>("ELSE","ELSE"));
	palavras_reservadas.insert(pair<string,string>("WHILE","WHILE"));
	palavras_reservadas.insert(pair<string,string>("DO","DO"));
	palavras_reservadas.insert(pair<string,string>("OR","OR"));
	palavras_reservadas.insert(pair<string,string>("AND","AND"));
	palavras_reservadas.insert(pair<string,string>("DIV","DIV"));
	palavras_reservadas.insert(pair<string,string>("NOT","NOT"));
	palavras_reservadas.insert(pair<string,string>("INTEGER","INTEGER"));
//	palavras_reservadas.insert(pair<string,string>("WRITE","WRITE"));
//	palavras_reservadas.insert(pair<string,string>("READ","READ"));
}

void setarSimbolosEspeciais(){
	simbolos_especiais.insert(pair<string,string>(".","."));
	simbolos_especiais.insert(pair<string,string>(",",","));
	simbolos_especiais.insert(pair<string,string>(";",";"));
	simbolos_especiais.insert(pair<string,string>("(","("));
	simbolos_especiais.insert(pair<string,string>(")",")"));
	simbolos_especiais.insert(pair<string,string>(":",":"));
	simbolos_especiais.insert(pair<string,string>("=","="));
	simbolos_especiais.insert(pair<string,string>("<","<"));
	simbolos_especiais.insert(pair<string,string>(">",">"));
	simbolos_especiais.insert(pair<string,string>("<=","<="));
	simbolos_especiais.insert(pair<string,string>(">=",">="));
	simbolos_especiais.insert(pair<string,string>("+","+"));
	simbolos_especiais.insert(pair<string,string>("-","-"));
	simbolos_especiais.insert(pair<string,string>("*","*"));
	simbolos_especiais.insert(pair<string,string>(":=",":="));
	simbolos_especiais.insert(pair<string,string>("(*","(*"));
	simbolos_especiais.insert(pair<string,string>("*)","*)"));
}

void setarConjuntos(){
	//setar letras
	for(char letra='A';letra<='Z';letra++){
		letras.insert(letra);
	}
	
	//setar digitos
	for(char digito='0';digito<='9';digito++){
		digitos.insert(digito);
	}

	setarSimbolosCompostos();

	setarSimbolosEspeciais();
}


void PROXIMO(){
	if(fim_arquivo){
		fechar_arquivo();
//		cout << "Arquivo \"Analise_Lexica.txt\" com codigo intermediario criado";
		escrever_intermediario();
	}
		
	if(pular_linha){		//chama PROXIMO antes de salvar codigo atual na linha anterior, entao avanca a linha somente quando for ler o primeiro codigo da nova linha
//		cout << "\n";
		
		linha++;
		pular_linha=false;
	}
	if(proximo!='\t'&&proximo!=' ')
		anterior=proximo;
	if(fread(&proximo,sizeof(char),1,fonte)==1){
		proximo=toupper(proximo);
		if(proximo=='\n'){
			linhaReal++;
			if(anterior!='\n'){
				pular_linha=true;
				simbolo.push_back(vector<string>());
			}
		}
	}
	else{
		proximo = ' ';	
		fim_arquivo=true;	//fecha o programa depois de salvar os dados que estão sendo lidos atualmente
	}

}

string codigo_identificador(string atomo){
	
	if(identificadores.find(atomo)!=identificadores.end()){		//identificador já usado
		return identificadores[atomo];
	}
	else{		//primeira vez usando identificador
		idNum++;
		string cod="id";
		cod+=to_string(idNum);
		ordem.push_back(atomo);
		identificadores[atomo]=cod;
		return cod;
	}
}

string codigo_numero(string atomo){	
		string cod="num_";
		cod+=atomo;
		return cod;
	
}

string CODIGO(string atomo,int tipo){
	if(tipo == 0){		//simbolos especiais
		return simbolos_especiais[atomo];
	}
	else if(tipo == 1)	//palavras reservadas
		return palavras_reservadas[atomo];
	else if(tipo == 2)	//identificadores
		return codigo_identificador(atomo);
	else if(tipo == 3) //numeros
		return codigo_numero(atomo);
}

void ERRO(int tipo){
	if(tipo==0){
		cout << "ERRO NA LINHA " << linhaReal << ": identificador ou numero mal formado";
		fechar_arquivo();
		exit(0);
	}
	if(tipo==1){
		cout << "ERRO NA LINHA " << linhaReal << ": simbolo nao identificado";
		fechar_arquivo();
		exit(0);
	}
	if(tipo==2){
		if(erro[0]=='I' && erro[1]=='D'){
			erro=string(erro.begin()+2,erro.end());
			int indice=stoi(erro);
			erro=ordem[indice-1];
		}
		if(erro[0]=='N' && erro[1]=='U' && erro[2]=='M'){
			erro=string(erro.begin()+4,erro.end());
		}
		
		cout << "ERRO NA LINHA " << linhaReal << ": esperado " << certo << " antes de " << erro <<"\n";
		exit(0);
	}
}

bool comentario(){		//dentro do comentario nao tem erro de simbolo desconhecido
	while(true){	
		while(proximo!='*'&& !fim_arquivo){	
			if(proximo=='\n')
				pular_linha=false; //nao pula de linha em comentario
			PROXIMO();
		}
		if(fim_arquivo)
			return false;
		PROXIMO();
		if(proximo==')'){
			PROXIMO();
			return true;
		}
	}
	
}

void Analisador_Lexico(){
	string atomo="";
	string s;
	while((proximo==' ' || proximo=='\t' || proximo=='\n') && !fim_arquivo){
		PROXIMO();
		
	}
	if(fim_arquivo)
		return;
	s=proximo;
	if(simbolos_especiais.find(s)!=simbolos_especiais.end()){
		PROXIMO();
		switch(s[0]){
			case 40:					//se s= (
				if(proximo=='*'){
					s="(*";
					PROXIMO();
					simbolo[linha-1].push_back(CODIGO(s,0));
						if(pular_linha){		//se ia pular linha logo depois comentario, ja pula antes de comecar a desconsiderar
//							cout << "\n";
							linha++;
							pular_linha=false;
						}
					if(comentario())
						simbolo[linha-1].push_back(CODIGO("*)",0));
					return;	//não salvar o codigo em simbolo 2 vezes
				}
				break;
			case 42:
				if(proximo==')'){
					s="*)";
					PROXIMO();
				}
				break;	
			case 58:					//se s= :
				if(proximo=='='){
					s=":=";
					PROXIMO();
				}
				break;	
			case 60:				//se s= <
				if(proximo=='='){
					s="<=";
					PROXIMO();
				}
				break;
			case 62:				//se s= >
				if(proximo=='='){
					s=">=";
					PROXIMO();
				}
				break;	
		}
		simbolo[linha-1].push_back(CODIGO(s,0));
//		cout << CODIGO(s,0) <<" ";
	}
	else if(letras.find(proximo)!=letras.end()){
		while(letras.find(proximo)!=letras.end()||digitos.find(proximo)!=digitos.end()){	//ler atomo inteiro
			atomo+=proximo;
			PROXIMO();
		}
		if(palavras_reservadas.find(atomo)!=palavras_reservadas.end()){
			simbolo[linha-1].push_back(CODIGO(atomo,1));
//			cout << CODIGO(atomo,1) << " ";
		}
		else{
			simbolo[linha-1].push_back(CODIGO(atomo,2));
//			cout  << CODIGO(atomo,2) << " ";
		}	
		
	}
	else if(digitos.find(proximo)!=digitos.end()){
		while(digitos.find(proximo)!=digitos.end()){
			atomo+=proximo;
			PROXIMO();
		}
		if(letras.find(proximo)!=letras.end())
			ERRO(0);
		simbolo[linha-1].push_back(CODIGO(atomo,3));
//		cout  << CODIGO(atomo,3) << " ";
	}
	else
		ERRO(1);	
}


// ----------------------------------------------------- Analise Sintatica ---------------------------------------------------------------------

void juntarPsi(set<string> & a,set<string> b){
	a.insert(b.begin(),b.end());
}

void setarPsi(){
	psi.insert({"LETRA",set<string>()});
	for(char letra='A';letra<='Z';letra++){
		psi["LETRA"].insert(string{letra});
	}
	psi.insert({"IDENTIFICADOR",psi["LETRA"]});
	psi.insert({"PARTE_VARIAVEIS",set<string>()});
	psi["PARTE_VARIAVEIS"].insert("VAR");
	psi.insert({"DIGITO",set<string>()});
	for(char digito='0';digito<='9';digito++){
		psi["DIGITO"].insert(string{digito});
	}
	psi.insert({"DECLARACAO_PROCEDIMENTO",set<string>({"PROCEDURE"})});
	psi.insert({"DECLARACAO_FUNCAO",set<string>({"FUNCTION"})});
	psi.insert({"PARTE_SUB_ROTINAS",psi["DECLARACAO_FUNCAO"]});
	juntarPsi(psi["PARTE_SUB_ROTINAS"], psi["DECLARACAO_PROCEDIMENTO"]);
	psi.insert({"COMANDO_COMPOSTO",set<string>({"BEGIN"})});
	psi.insert({"PARAMETROS_FORMAIS",set<string>({"("})});
	psi.insert({"COMANDO_CONDICIONAL",set<string>({"IF"})});
	psi.insert({"COMANDO_REPETITIVO",set<string>({"WHILE"})});
	psi.insert({"RELACAO",set<string>({"=","<>","<","<=","=>",">"})});
}

bool v_psi(string ind, string var){
	return psi[ind].find(var)!=psi[ind].end();
}

volta(string p){
	fseek(fonte,-p.size()-1,SEEK_CUR);
}

string palavra(){
	string p="";
	//achar comeco palavra
	while(proximo==' ' || proximo=='\n' || proximo =='\t' || digitos.find(proximo)!=digitos.end()){
		PROXIMO();
	}
	
	//ler palavra inteira
	do{
		p+=proximo;
		PROXIMO();
	}while(proximo!=' ' && proximo !='\n' && proximo !='\t');
	
	//voltar ponteiro se não for palavra reservada

		
	return p;
}

void DIGITO(){
	if(digitos.find(proximo)==digitos.end()){
		certo="numero";
		erro=string{proximo};
		ERRO(2);
	}
			
}


void LETRA(){
	if(letras.find(proximo)==letras.end()){
		certo="identificador";
		erro=string{proximo};
		ERRO(2);
	}
		
}

void IDENTIFICADOR(){
	while(proximo==' ' || proximo=='\n' || proximo =='\t' || digitos.find(proximo)!=digitos.end()){
		PROXIMO();
	}
	if(proximo=='I'){
		PROXIMO();
		if(proximo=='D'){
			do{
				PROXIMO();
				if(v_psi("LETRA",string{proximo}))
					LETRA();
				else if(v_psi("DIGITO",string{proximo}))
					DIGITO();
				else
					break;
			}while(true);
		}
		else{
			proximo=' ';
			volta("I");
			certo="identificador";
			erro=palavra();
			ERRO(2);
		}
	}
	else{
		proximo=' ';
		certo="identificador";
		erro=palavra();
		ERRO(2);
	}
	
}

void LISTA_IDENTIFICADORES(){
	IDENTIFICADOR();
	string var=palavra();
	while(var==","){
		IDENTIFICADOR();
		var=palavra();
	}
	volta(var); //voltar cursor
}

void LISTA_EXPRESSOES(){
	EXPRESSAO();
	string var=palavra();
	while(var==","){
		EXPRESSAO();
		var=palavra();
	}
	volta(var); //voltar cursor
}

void CHAMADA_FUNCAO(){
	string var=palavra();
	if(var=="("){
		LISTA_EXPRESSOES();
		var=palavra();
		if(var!=")"){
			certo=")";
			erro=var;
			ERRO(2);
		}
	}
	else{
		volta(var);
	}
}

void FATOR(){
	string var=palavra();
	if(var=="("){
		EXPRESSAO();
		var=palavra();
		if(var!=")"){
			certo=")";
			erro=var;
			ERRO(2);
		}
	}
	else if(var=="NOT"){
		FATOR();
	}
	else if(string(var.begin(),var.begin()+4)=="NUM_"){
		//numero
	}
	else{
		volta(var);
		IDENTIFICADOR();
		var=palavra();
		volta(var);
		if(var=="(")
			CHAMADA_FUNCAO();

	}
}

void TERMO(){
	FATOR();
	string var=palavra();
	while(var=="*" || var=="DIV" || var== "AND"){
		FATOR();
		var=palavra();
	}
	volta(var);
}

void RELACAO(){
	string var=palavra();
	if(!v_psi("RELACAO",var)){
		certo="\'comparador\'";
		erro=var;
		ERRO(2);
	}
}

void EXPRESSAO_SIMPLES(){
	string var=palavra();
	if(var!="+" && var!="-")
		volta(var);
	TERMO();
	var=palavra();
	while(var=="+" || var=="-" || var== "OR"){
		TERMO();
		var=palavra();
	}
	volta(var);
}

void EXPRESSAO(){
	EXPRESSAO_SIMPLES();
	string var=palavra();
	volta(var);
	if(v_psi("RELACAO",var)){
		RELACAO();
		EXPRESSAO_SIMPLES();
	}
}

void ATRIBUICAO(){
	string var=palavra();
	if(var==":=")
		EXPRESSAO();
	else{
		certo=":=";
		erro=var;
		ERRO(2);
	}
}

void CHAMADA_PROCEDIMENTO(){
	string var=palavra();
	if(var=="("){
		LISTA_EXPRESSOES();
		var=palavra();
		if(var!=")"){
			certo=")";
			erro=var;
			ERRO(2);
		}
	}
	else{
		volta(var);
	}
}

void COMANDO_CONDICIONAL(){
	string var;
	EXPRESSAO();
	var=palavra();
	
	if(var=="THEN"){
		COMANDO_SEM_ROTULO();
		var=palavra();
		if(var=="ELSE"){
			COMANDO_SEM_ROTULO();
		}
		else
			volta(var);
	}
	else{
		certo="THEN";
		erro=var;
		ERRO(2);
	}
}

void COMANDO_REPETITIVO(){
	EXPRESSAO();
	string var=palavra();
	if(var=="DO"){
		COMANDO_SEM_ROTULO();
	}
	else{
		certo="DO";
		erro=var;
		ERRO(2);
	}
}

void COMANDO_SEM_ROTULO(){
	string var=palavra();
	
	if(v_psi("COMANDO_COMPOSTO",var)){
		volta(var);
		COMANDO_COMPOSTO();
	}
	else if(v_psi("COMANDO_REPETITIVO",var)){
		COMANDO_REPETITIVO();
	}
	else if(v_psi("COMANDO_CONDICIONAL",var)){
		COMANDO_CONDICIONAL();
	}
	else{
		volta(var);
		IDENTIFICADOR();
		var=palavra();
		volta(var);
		if(var==":="){
			ATRIBUICAO();
		}
		else{
			CHAMADA_PROCEDIMENTO();
		}
	}
}

void COMANDO(){
	COMANDO_SEM_ROTULO();
}

void COMANDO_COMPOSTO(){
	string var=palavra();
	if(var=="BEGIN"){
		COMANDO();
		var=palavra();
		while(var==";"){
			var=palavra();
			if(var=="END")
				break;
			else
				volta(var);
			COMANDO();
			var=palavra();
		}
		if(var!="END"){
			certo="END";
			erro=var;
			ERRO(2);
		}
	}
	else{
		certo="BEGIN";
		erro=var;
		ERRO(2);
	}
}

void SECAO_PARAMETROS_FORMAIS(){
	string var=palavra();
	if(var!="VAR")
		volta(var);
	LISTA_IDENTIFICADORES();
	var=palavra();
	if(var==":"){
		var=palavra();
		if(var!="INTEGER"){
			certo=" \'tipo\'";
			erro=var;
			ERRO(2);
		}
	}
	else{
		certo=":";
		erro=var;
		ERRO(2);
	}
}

void PARAMETROS_FORMAIS(){
	SECAO_PARAMETROS_FORMAIS();
	string var=palavra();
	while(var==";"){
		SECAO_PARAMETROS_FORMAIS();
		var=palavra();
	}
	if(var!=")"){
		certo=")";
		erro=var;
		ERRO(2);
	}
}

void DECLARACAO_PROCEDIMENTO(){
	IDENTIFICADOR();
	string var=palavra();
	if(v_psi("PARAMETROS_FORMAIS",var)){
		PARAMETROS_FORMAIS();
		var=palavra();
	}
	if(var==";"){
		BLOCO();
	}
	else{
		certo=";";
		erro=var;
		ERRO(2);
	}
}

void DECLARACAO_FUNCAO(){
	IDENTIFICADOR();
	string var=palavra();
	if(v_psi("PARAMETROS_FORMAIS",var)){
		PARAMETROS_FORMAIS();
		var=palavra();
	}
	if(var==":"){
		var=palavra();
		if(var=="INTEGER"){
			var=palavra();
			if(var==";"){
				BLOCO();
			}
			else{
				certo=";";
				erro=var;
				ERRO(2);
			}
		}
		else{
			certo=" \'tipo\'";
			erro=var;
			ERRO(2);
		}
	}
	else{
		certo=":";
		erro=var;
		ERRO(2);	
	}
	
}

void PARTE_SUB_ROTINAS(){
	string var=palavra();
	do{	
		if(v_psi("DECLARACAO_PROCEDIMENTO",var))
			DECLARACAO_PROCEDIMENTO();
		else if(v_psi("DECLARACAO_FUNCAO",var))
			DECLARACAO_FUNCAO();
		else{
			certo="FUNCTION ou PROCEDURE";
			erro=var;
			ERRO(2);
		}
		var=palavra();
		if(var!=";"){
			certo=";";
			erro=var;
			ERRO(2);
		}
		var=palavra();
	}while(v_psi("PARTE_SUB_ROTINAS",var));
	volta(var);
}



void DECLARACAO_VARIAVEIS(){
	LISTA_IDENTIFICADORES();
	string var=palavra();
	if(var==":"){
		var=palavra();
		if(var!="INTEGER"){
			certo=" \'tipo\'";
			erro=var;
			ERRO(2);
		}
			
	}
	else{
		certo=":";erro=var;
		ERRO(2);
	}
		
}

void PARTE_VARIAVEIS(){
	string var=palavra();
	if(var=="VAR"){
		DECLARACAO_VARIAVEIS();
		var=palavra();
		if(var==";"){
			var=palavra();
			while(!v_psi("PARTE_SUB_ROTINAS",var) && !v_psi("COMANDO_COMPOSTO",var)){
				DECLARACAO_VARIAVEIS();
				var=palavra();
				if(var==";")
					var=palavra();
				else{
					certo=";";erro=var;
					ERRO(2);
				}
					
			}
			volta(var);
		}
		else{
			certo=";";erro=var;
			ERRO(2);
		}
			
	}
	else{
		certo="VAR";erro=var;
		ERRO(2);
	}
		
}

void BLOCO(){
	string var=palavra();
	volta(var); //voltar cursor para quando função for ler a variável
	if(v_psi("PARTE_VARIAVEIS",var)){
		PARTE_VARIAVEIS();
		var=palavra();
		volta(var);
	}
		
	if(v_psi("PARTE_SUB_ROTINAS",var)){
		PARTE_SUB_ROTINAS();
	}
	COMANDO_COMPOSTO();
}

void PROGRAMA(){
	string var=palavra();
	if(var == "PROGRAM"){
//		var=palavra();
		IDENTIFICADOR();
		var=palavra();
		if(var==";"){
//			PROXIMO();
			BLOCO();
			var=palavra();
			if(var=="."){
				var=palavra();
				if(var=="#")
					cout << "SUCESSO :D !!!!!";
				else{
					certo="fim do programa";erro=var;
					ERRO(2);
				}
					
			}
			else{
				certo=".";erro=var;
				ERRO(2);
			}
				
		}
		else{
			certo=";";erro=var;
			ERRO(2);
		}
			
	}
	else{
		certo="PROGRAM";erro=var;
		ERRO(2);
	}
}






void Analisador_Sintatico(){
	PROGRAMA();
}

int main(){
	
	//ANALISADOR LEXICO
	
	simbolo.push_back(vector<string>()); //iniciar primeira linha tabela de simbolos
	setarConjuntos();
	abrir_arquivo("Exemplo1_Trab2_Compiladores.txt","r");
	while(true){
		Analisador_Lexico();
		if(fim_arquivo){
			PROXIMO();
			break;
		}	
	}
	
	//ANALISADOR SINTATICO
	
	
	
	//resetar variaveis auxilio
	linha=1;			//linha erro e tabela simbolo
	linhaReal=1;		//linha contando pular linha duas vezes seguidas em comentários
	proximo=' ';		//caractere a analisar
	anterior='a';		//caractere anterior para troca de linha 
	pular_linha=false;
	fim_arquivo=false;	//salvar informacao antes de fechar programa
	
	//setar psi
	setarPsi();
	
	abrir_arquivo("Analise_Lexica.txt","r");
	Analisador_Sintatico();
}
//
