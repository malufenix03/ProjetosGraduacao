#JOGO DA COBRINHA EM PYTHON POR https://github.com/mauricior/
#Aplicação de um agente inteligente no jogo

from tkinter import *
from tkinter.messagebox import showinfo
import random
import numpy as np
from collections import defaultdict
import pickle
import shutil
import os

width = 100
heigh = 100
grid_size = 20
ponto= 0


class square:


    def __init__(self, x, y, color):
        self.x = x
        self.y = y 
        self.color = color
        self.velx = 0
        self.vely = 0
        self.dim = [0,0, 0,grid_size, grid_size, grid_size,grid_size, 0]


    def setVel(self, newx, newy):
        self.velx = newx
        self.vely = newy

    def pos(self):
        return [self.dim[0] + self.x, self.dim[1] + self.y, self.dim[2] + self.x, self.dim[3] + self.y, self.dim[4] + self.x, self.dim[5] + self.y, self.dim[6] + self.x, self.dim[7] + self.y]



                
    def update(self):
        if(self.x>0 and self.x<width-grid_size):
            self.x += self.velx
        if(self.y>0 and self.y<heigh-grid_size):
            self.y += self.vely
        if(self.x==0 and self.velx>0):
            self.x += self.velx
        if(self.x==width-grid_size and self.velx<0):
            self.x += self.velx
        if(self.y==0 and self.vely >0):
            self.y += self.vely
        if(self.y==heigh-grid_size and self.vely <0):
            self.y += self.vely


class Game:

    def __init__(self):
        self.window = Tk()
        self.canvas = Canvas(self.window, bg='black', width=width, heigh=heigh)
        self.canvas.pack()

        s = square(20, 20, 'white')         #cobra
        s1 = square(20, 20 ,'white')        #cobra
        s2 = square(20, 20, 'white')        #cobra
        s3 = square(20, 20, 'white')        #cobra

        f = square(random.randint(1,int(width/grid_size))*grid_size - grid_size, random.randint(1, int(heigh/grid_size))*grid_size - grid_size, 'purple')       #comida
        self.snake = [s, s1, s2, s3]
        self.food = [f]
        self.vel = [[20,0], [0,0], [0,0], [0,0]]
        pos=self.snake[0].pos()
        while(pos in [(s.x,s.y) for s in self.snake]):
                self.food[0].x = random.randint(1, int(width/grid_size))*grid_size-grid_size
                self.food[0].y = random.randint(1, int(heigh/grid_size))*grid_size-grid_size
                pos=self.food[0].x, self.food[0].y

        #variaveis para aprendizado por reforço
        self.q_table = self.lerQ()      #o valor de cada uma das ações em um estado, up, down, left, right
        self.learning_rate = 0.85       #taxa de apredizado
        self.discount_factor = 0.9      #fator de desconto para recompensas futuras
        self.exploration_rate = 0.00     #taxa de exploração em vez de pegar a melhor ação
        self.exploration_decay = 1  #taxa de decaimento

        self.window.bind("<Up>", self.moveUp)
        self.window.bind("<Down>", self.moveDown)
        self.window.bind("<Right>", self.moveRight)
        self.window.bind("<Left>", self.moveLeft)
        self.window.bind("<space>", self.pause)
        self.flag=True

    def zeros(self):
        return np.zeros(4)

    def pause(self,event):
        if(self.flag):
            self.flag=False
        else:
            self.flag=True
        return

    def restart(self):
        s = square(20, 20, 'white')         #cobra
        s1 = square(20, 20 ,'white')        #cobra
        s2 = square(20, 20, 'white')        #cobra
        s3 = square(20, 20, 'white')        #cobra

        f = square(random.randint(0,int(width/grid_size) - 1)*grid_size, random.randint(0,int(width/grid_size) - 1)*grid_size, 'purple')       #comida
        self.snake = [s, s1, s2, s3]
        self.food = [f]
        self.vel = [[20,0], [0,0], [0,0], [0,0]]
        pos=self.snake[0].pos()
        while(pos in [(s.x,s.y) for s in self.snake]):
                self.food[0].x = random.randint(0, (width // grid_size) - 1) * grid_size
                self.food[0].y = random.randint(0, (heigh // grid_size) - 1) * grid_size
                pos=self.food[0].x, self.food[0].y


    def moveUp(self, event):
        if(self.vel[0] != [0,20]):
            self.vel[0] = [0,-20]
    def moveDown(self, event):
        if(self.vel[0] != [0,-20]):
            self.vel[0] = [0,20]
    def moveRight(self, event):
        if(self.vel[0] != [-20,0]):
            self.vel[0] = [20,0]
    def moveLeft(self, event):
        if(self.vel[0] != [20,0]):
            self.vel[0] = [-20,0]

    def estado_atual(self):
        pos_cabeca = (self.snake[0].x, self.snake[0].y)
        final=len(self.snake)
        pos_cauda = tuple((s.x,s.y) for s in self.snake[1:])
        pos_comida = self.food[0].x,self.food[0].y
        return pos_cabeca, pos_cauda, pos_comida

    def escolher_acao(self,estado):
        #aleatório ou valores já validados
        if random.uniform(0,1) < self.exploration_rate:
             #print("aleatorio IIIII")
             return random.choice(range(4))
        else:
            return np.argmax(self.q_table[estado])

    def executar_acao(self,acao):
        if acao == 0:   #cima
            self.moveUp(None)
        elif acao == 1:
            self.moveDown(None) #baixo
        elif acao == 2: #direita
            self.moveRight(None)
        elif acao == 3: #esquerda
            self.moveLeft(None)

    def updateQ(self,atual,novo,recompensa,acao):
     #   print(self.q_table[atual])
        q0 = self.q_table[atual]
        q1 = self.q_table[novo]
    #    print("antes ",q0[acao])
        valor=recompensa+self.discount_factor*np.max(q1)-q0[acao]
    #    print("futuro ",np.max(q1))
    #    print("variavel ",valor)
    #    print("recompensa ",recompensa)
        self.q_table[atual][acao]=q0[acao]+self.learning_rate*valor
   #     print(self.q_table[atual][acao])
   #     print(self.q_table[atual])
        return 0


    def converter(self,direcao):
        if(not direcao):
            return random.choice(range(4))
        if(direcao[1]<0):
            return 0    #cima
        elif(direcao[1]>0):
            return 1    #baixo
        elif(direcao[0]>0):
            return 2    #direita
        elif(direcao[0]<0):
            return 3    #esquerda

    def lerQ(self):
        try:
            with open('qtable.pkl', 'rb') as arquivo:
                carregar = pickle.load(arquivo)
        except (FileNotFoundError, EOFError):
            with open('qtable.pkl','wb') as arquivo:
                pass
            carregar = {}
        return defaultdict(self.zeros,carregar)


    def run(self):
        counter = 0
        while(True):
            self.canvas.delete('all')          #apaga o que já estava desenhado

            estado_atual=self.estado_atual()
            acao=self.escolher_acao(estado_atual)
            self.executar_acao(acao)
            dist=self.heuristica((self.food[0].x,self.food[0].y),(self.snake[0].x,self.snake[0].y))
            recompensa_instatanea=-1
            # Atualiza a posição da cobrinha
            for i in range(len(self.vel)-1, 0, -1):
                self.vel[i] = self.vel[i-1]

            for i in range(len(self.vel)):
                self.snake[i].velx = self.vel[i][0]
                self.snake[i].vely = self.vel[i][1]

            
#            if(dist>self.heuristica((self.food[0].x,self.food[0].y),(self.snake[0].x,self.snake[0].y))):
 #               recompensa_instatanea=0.1

            # Verifica se a cobrinha comeu a comida
            if(self.snake[0].pos() == self.food[0].pos()):
                global ponto
                ponto=ponto+1
                #print(ponto)
                recompensa_instatanea=5
                self.food[0].x = random.randint(0, (width // grid_size) - 1) * grid_size
                self.food[0].y = random.randint(0, (heigh // grid_size) - 1) * grid_size
                pos=self.food[0].x, self.food[0].y
                while(pos in [(s.x,s.y) for s in self.snake]):
                    self.food[0].x = random.randint(0, (width // grid_size) - 1) * grid_size
                    self.food[0].y = random.randint(0, (heigh // grid_size) - 1) * grid_size
                    pos=self.food[0].x, self.food[0].y
                self.vel.append([0,0])
                self.snake.append(square(self.snake[-1].x, self.snake[-1].y, self.snake[0].color))

            
            
            # Atualiza e desenha os elementos
            for s in self.snake:
                s.update()
                self.canvas.create_polygon(s.pos(), fill=s.color)
                
            for f in self.food:
                f.update();
                self.canvas.create_polygon(f.pos(), fill=f.color)
            novo_estado=self.estado_atual()
            for i in range(2, len(self.snake)):
                if(counter < 1):
                    counter += 1
                elif(self.snake[0].pos() == self.snake[i].pos()):
                    self.exploration_rate=self.exploration_decay*self.exploration_rate
                    recompensa_instatanea=-10
                   # print(self.snake[0].x)
                   # print(self.snake[0].y)
                    self.q_table[novo_estado]=np.full(4,-10)
                    #showinfo(title="Game Over",message= "GAME OVER!!!")
                    self.restart()
                    break
                            
            if(self.flag):
                self.canvas.after(100)
            else:
                self.canvas.after(50)
            self.window.update_idletasks()
            self.window.update()

    def heuristica(self,a,b):
        return abs(a[0]-b[0])+abs(a[1]-b[1])    #diferença absoluta entre as coordenadas x,y


    def posicao_valida(self,pos):
        x,y=pos
        return  (0 <= x < width and 0 <= y < heigh) and (pos not in [(s.x,s.y) for s in self.snake])





g = Game()
g.run()