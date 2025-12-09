#JOGO DA COBRINHA EM PYTHON POR https://github.com/mauricior/
#Aplicação de um agente inteligente no jogo

from tkinter import *
from tkinter.messagebox import showinfo
import random
import numpy as np
from collections import defaultdict

width = 800
heigh = 600
grid_size = 20


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

        f = square(random.randint(grid_size,int(width/grid_size))*grid_size - grid_size, random.randint(grid_size, int(heigh/grid_size))*grid_size - grid_size, 'purple')       #comida
        self.snake = [s, s1, s2, s3]
        self.food = [f]
        self.vel = [[20,0], [0,0], [0,0], [0,0]]
        pos=self.snake[0].pos()
        while(pos in [(s.x,s.y) for s in self.snake]):
                self.food[0].x = random.randint(grid_size, int(width/grid_size))*grid_size-grid_size
                self.food[0].y = random.randint(grid_size, int(heigh/grid_size))*grid_size-grid_size
                pos=self.food[0].x, self.food[0].y

        self.window.bind("<Up>", self.moveUp)
        self.window.bind("<Down>", self.moveDown)
        self.window.bind("<Right>", self.moveRight)
        self.window.bind("<Left>", self.moveLeft)


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

    def run(self):
        counter = 0
        while(True):
            self.canvas.delete('all')          #apaga o que já estava desenhado
             
            #pegar a posicao da cobrinha e da comida
            cabeca = (self.snake[0].x,self.snake[0].y)
            comida = (self.food[0].x,self.food[0].y)

            path = self.a_star(cabeca,comida)

            if path:
                proximo=path[0]
                self.vel[0] = [proximo[0]-cabeca[0], proximo[1]-cabeca[1]]

            # Atualiza a posição da cobrinha
            for i in range(len(self.vel)-1, 0, -1):
                self.vel[i] = self.vel[i-1]

            for i in range(len(self.vel)):
                self.snake[i].velx = self.vel[i][0]
                self.snake[i].vely = self.vel[i][1]

            

            # Verifica se a cobrinha comeu a comida
            if(self.snake[0].pos() == self.food[0].pos()):
                self.food[0].x = random.randint(grid_size, int(width/grid_size))*grid_size-grid_size
                self.food[0].y = random.randint(grid_size, int(heigh/grid_size))*grid_size-grid_size
                pos=self.food[0].x, self.food[0].y
                while(pos in [(s.x,s.y) for s in self.snake]):
                    self.food[0].x = random.randint(grid_size, int(width/grid_size))*grid_size-grid_size
                    self.food[0].y = random.randint(grid_size, int(heigh/grid_size))*grid_size-grid_size
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
            
            for i in range(2, len(self.snake)  ):
                if(counter < 1):
                    counter += 1
                elif(self.snake[0].pos() == self.snake[i].pos()):
                    showinfo(title="Game Over",message= "GAME OVER!!!")
                    exit()


            self.canvas.after(70)
            self.window.update_idletasks()
            self.window.update()

    def heuristica(self,a,b):
        return abs(a[0]-b[0])+abs(a[1]-b[1])    #diferença absoluta entre as coordenadas x,y


    def posicao_valida(self,pos):
        x,y=pos
        return  (0 <= x < width and 0 <= y < heigh) and (pos not in [(s.x,s.y) for s in self.snake])



    def a_star(self,cabeca,comida):
        nos=[]
        explorados=set()
        custo_g = {cabeca: 0}
        custo_f = {cabeca: self.heuristica(cabeca,comida)}
        no_pai={}

        nos.append(cabeca)
        while nos:
            #no de menor custo
            atual = min(nos, key= lambda x: custo_f.get(x,float('inf')))
            if atual == comida and comida!=cabeca:
                #fazer o caminho
                caminho= []
                while atual in no_pai:
                    caminho.append(atual)
                    atual= no_pai[atual]
                return caminho[::-1]    #inverte o caminho para ficar na ordem correta
            nos.remove(atual)
            explorados.add(atual)

            vizinhos = [(atual[0]+dx, atual[1]+dy) for dx, dy in [(20,0),(-20,0),(0,20),(0,-20)]]
            for n in vizinhos:      #verifica os vizinhos
                if n in explorados or not self.posicao_valida(n):
                    continue
                custo_tentativa=custo_g[atual] + 1

                if n not in nos:
                    nos.append(n)
                    if comida==cabeca:
                        return [n]
                elif custo_tentativa >= custo_g.get(n,float('inf')):    #se ja achou caminho menor para vizinho deixa como esta
                    continue

                no_pai[n]=atual
                custo_g[n]=custo_tentativa
                custo_f[n]=custo_g[n]+self.heuristica(n,comida)
            

        # Se não encontrou caminho, tenta um vizinho válido
        vizinhos = [(cabeca[0] + dx, cabeca[1] + dy) for dx, dy in [(20, 0), (-20, 0), (0, 20), (0, -20)]]
        vizinhos_validos = [v for v in vizinhos if self.posicao_valida(v) and v != (self.snake[1].x, self.snake[1].y)]
        if vizinhos_validos:
            return [vizinhos_validos[0]]   #se nao achar caminho
        return []




g = Game()
g.run()