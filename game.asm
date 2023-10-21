.data
	m_pede_letra: .asciiz "\nDigite uma letra = "
	m_entrada_invalida: .asciiz "Entrada inválida.\n"
	m_letra_certa: .asciiz "Muito bem! Letra correta.\n"
	m_letra_errada: .asciiz "Ops! A palavra não contém essa letra.\n"
	m_deu_forca: .asciiz "Que pena! Deu forca e a palavra secreta era: "
	m_acertou_palavra: .asciiz "Parabéns! Você acertou a palavra secreta.\n"
	m_erro_abrir_arquivo: .asciiz "\nErro ao abrir arquivo.\n"
	m_erro_ler_arquivo: .asciiz "\nErro ao ler arquivo.\n"
	m_erro_tamanho_excedido: .asciiz "\nErro: Tamanho da palavra excedeu 31 caracteres.\n"
	pula_linha: .asciiz "\n"

	# Descomentar 'palavra_secreta' caso queira uma palavra pré-definida
	# Lembrar de descomentar o bloco relacionado na main
	# palavra_secreta: .asciiz "guarda-chuva"

	# Arquivo com as palavras do jogo
	arquivo: .asciiz "palavras.txt"
	# Número de palavras dentro do arquivo
	qtd_palavras: .word 4
	# Buffer para armazenar caractere lido no arquivo
	buffer: .space 1
	# Buffer para armazenar cada linha do arquivo
	linha: .space 32

	# Variáveis mapeadas para o jogo
	# Palavra secreta = $s6
	# Palavra in-game (PIG) = $s0 -> endereço 0x10000000
	# Tamanho da palavra = $s5
	# Status do game = $s4 -> endereço 0x10010500
	# Contador de erros = $s3
	# Contador de erros auxiliar para interface = $s2 -> endereço 0x10010600
	
.text
	main:
		# Endereço de memória base para a palavra in-game
		lui $s0, 0x1000
		# Endereço de memória base para o status do game
		li $s4, 0x10010500
		# Endereço de memória base para o contador auxiliar
		li $s2, 0x10010600

		# Caso queira uma palavra pré-definida: Descomentar este bloco e comentar o bloco seguinte
		# Carregar palavra secreta pré-definida
		# la $s6, palavra_secreta
		# li $s5, 0
		# jal carregar_palavra_secreta

		# Carregar palavra secreta aleatória do arquivo
		# 1: Abrir arquivo -> Descritor de arquivo = $s7
		jal abrir_arquivo
		# 2: Gerar número para definir palavra do jogo -> Número aleatório = $a0
		jal gerar_numero_aleatorio
		# 3: Ler palavra do arquivo na posição sorteada -> Tamanho da palavra = $s5; Palavra secreta = $s6
		# Entradas: $a0, $s7
		jal ler_palavra

		# Flag de carregar palavra
		li $t1, 1
		sw $t1, 0($s4)

		# Copiar palavra secreta para $t1
		move $t1, $s6
		# Criar máscara da palavra secreta (lacunas) -> Palavra in-game = $s0
		# Entradas: $t1, $s0, $s5
		jal criar_mascara_palavra

		# Flag de inicio de jogo
		li $t1, 2
		sw $t1, 0($s4)

		# Função inicializadora do jogo
		jal iniciar_jogo

		# Flag de fim de jogo
		li $t1, 3
		sw $t1, 0($s4)

		# Operações para finalização do jogo
		jal finalizar_jogo

		# Finalizar o programa
		jal fim_programa

	# Abrir arquivo para leitura
	# Modifica:
	#   Descritor de arquivo = $s7
	abrir_arquivo:
		li $v0, 13
		la $a0, arquivo
		li $a1, 0
		li $a2, 0
		syscall
		bltz $v0, erro_abrir_arquivo
		move $s7, $v0
		jr $ra
	
	# Lidar com erro ao abrir arquivo
	erro_abrir_arquivo:
		la $a0, m_erro_abrir_arquivo
		jal print_string
		j fim_programa
	
	# Gerar número aleatório para definir palavra sorteada
	# Modifica:
	#   Número aleatório (0 <= n <= qtd_palavras-1) = $a0
	gerar_numero_aleatorio:
		li $v0, 42
		li $a0, 74
		la $t0, qtd_palavras
		lw $a1, 0($t0)
		syscall
		jr $ra
	
	# Buscar e ler palavra sorteada
	# Parâmetros:
	#   Descritor de arquivo = $s7
	#   Número sorteado = $a0
	# Modifica:
	#   Tamanho da palavra = $s5
	#   Palavra secreta = $s6
	ler_palavra:
		la $t0, buffer
		la $t1, linha
		li $t2, 0		# Contador do tamanho da linha = $t2
		li $t6, 0		# Contador da linha = $t6
		move $t7, $a0   # Posição da palavra no arquivo = $t7

		loop_ler_palavra:
			# Comandos para leitura de 1 byte do arquivo
			move $a0, $s7
			move $a1, $t0
			li $a2, 1
			li $v0, 14
			syscall			# Byte salvo no endereço armazenado em $t0 (buffer)

			# Parar de ler quando der erro ($v0 < 0)
			bltz $v0, erro_ler_arquivo

			# Se quantidade de bytes da linha exceder 31 -> lançar erro e finalizar função
			slti $t3, $t2, 32
			beqz $t3, erro_tamanho_excedido

			# Se chegou no EOF -> finalizar função
			beqz $v0, terminador_nulo

			# Ler próximo byte
			lb $t4, 0($t0)                # Byte lido = $t4
			# Se byte == \r -> consumí-lo e voltar ao início do loop
			beq $t4, 13, consumir_CR
			# Se byte == \n -> fazer verificações
			beq $t4, 10, consumir_linha

			# Caso contrário -> concatenar byte na linha
			add $t5, $t1, $t2      # Ponteiro para linha = endereço inicial da linha + tamanho atual da linha
			sb $t4, 0($t5)         # Salvar byte na posição do ponteiro

			# Incrementar contador do tamanho da linha
			addi $t2, $t2, 1

			j loop_ler_palavra

		# Lidar com erro ao ler arquivo
		erro_ler_arquivo:
			la $a0, m_erro_ler_arquivo
			jal print_string
			j fim_programa
		
		# Colocar \0 no final da linha
		terminador_nulo:
			add $t5, $t1, $t2
			sb $zero 0($t5)
			j fim_ler_palavra

		# Apenas consumir o CR, caso exista
		consumir_CR:
			j loop_ler_palavra

		# Operações para quando chegar no final da linha
		consumir_linha:
			# Colocar \0 no final da linha
			add $t5, $t1, $t2    # Posicionar ponteiro no fim da string
			sb $zero 0($t5)

			# Se for a palavra sorteada -> finalizar laço
			beq $t6, $t7, fim_ler_palavra    # Se contador da linha == numero sorteado

			# Caso contrário -> ler próxima linha
			addi $t6, $t6, 1    # Incrementa contador da linha
			li $t2, 0           # Reseta contador do tamanho da linha

			j loop_ler_palavra

	# Operações para finalizar a função
	fim_ler_palavra:
		# Fechar arquivo
		li $v0, 16
		move $a0, $s7
		syscall

		# Copiar palavra para $s6
		move $s6, $t1

		# Copiar tamanho da palavra para $s5
		move $s5, $t2

		jr $ra

	# Carregar palavra secreta pré-definida (opcional)
	# Parâmetros:
	#   Palavra secreta = $s6
	# Modifica:
	#   Tamanho da palavra = $s5
	carregar_palavra_secreta:
		# Ponteiro para varrer a palavra secreta
		move $t3, $s6

		loop_cps:
			# Ler caractere da palavra secreta
			lb $t0, 0($t3)

			# Se quantidade de bytes da linha exceder 31 -> lançar erro e finalizar função
			slti $t1, $s5, 32
			beqz $t1, erro_tamanho_excedido

			# Se chegar no final da palavra -> finalizar função
			beqz $t0, fim_cps

			# Incrementa tamanho da palavra
			addi $s5, $s5, 1

			# Incrementa ponteiro da palavra
			addi $t3, $t3, 1

			j loop_cps

	# Finalizar função
	fim_cps:
		jr $ra

	# Lidar com erro de tamanho da palavra que excedeu 31 caracteres
	erro_tamanho_excedido:
		la $a0, m_erro_tamanho_excedido
		jal print_string
		j fim_programa

	# Criar máscara da PIG (lacunas)
	# Parâmetros:
	#   Palavra secreta = $t1
	#   Tamanho da palavra = $s5
	# Modifica:
	#   PIG = $s0
	criar_mascara_palavra:
		# Carrega o caractere da posição atual da palavra em $t2
		lb $t2, 0($t1)
		# Se chegar no final da palavra -> finalizar função
		beqz $t2, fim_cmp

		# Comparações
		li $t3, 45    #Caratere '-'
		beq $t2, $t3, copiar_caractere

		li $t3, 32    #Caratere espaço
		beq $t2, $t3, copiar_caractere

		li $t2, 95    #Caratere '_'

		# Salvar caractere designado na PIG
		copiar_caractere:
			sb $t2, 0($s0)
			# Incrementa ponteiro da palavra
			addi $t1, $t1, 1
			# Incrementa ponteiro da mascara
			addi $s0, $s0, 1

		j criar_mascara_palavra

	# Finalizar função
	fim_cmp:
		sub $s0, $s0, $s5
		jr $ra
	
	# Função inicializadora do jogo
	# Parâmetros:
	#   Contador de erros = $s3
	#   Contador de erros auxiliar = $s2
	#   Palavra secreta = $s6
	#   PIG = $s0
	iniciar_jogo:
		# Salvar $ra na pilha
		addi $sp, $sp, -4
		sw $ra, 0($sp)

		# Iniciar contador de erros
		li $s3, 0

		# Loop principal do jogo
		loop_jogo:
			# Verificar se o jogo finalizou
			# Entradas: $s3, $s0
			jal verificar_fim_jogo

			# Solicitar letra do jogador
			inicio_solicitar_letra:
				la $a0, m_pede_letra
				jal print_string
				jal ler_caractere    # Caractere digitado = $v0

			# Caractere digitado = $t0
			move $t0, $v0

			# Validar caractere digitado pelo jogador
			# Entradas: $t0
			jal validar_entrada

			# Copiar palavra secreta para $t1
			move $t1, $s6
			# Verificar se a palavra secreta contém o caractere digitado
			# Entradas: $t0, $t1
			jal verificar_contem_letra

			# Instruções caso a palavra contenha a letra digitada
			inicio_contem_letra:
				# Mensagem de letra correta
				jal print_nova_linha
				la $a0, m_letra_certa
				jal print_string

				# Copiar PIG para $t1
				move $t1, $s0
				# Copiar palavra secreta para $t2
				move $t2, $s6
				# Atualizar PIG com a letra digitada nas lacunas correspondentes
				# Entradas: $t0, $t1, $t2
				jal atualizar_PIG

				j final_bloco
			
			# Instruções caso a palavra NÃO contenha a letra digitada
			inicio_nao_contem_letra:
				# Incrementar contador de erros
				addi $s3, $s3, 1
				# Atualizar contador auxiliar para refletir na interface
				sw $s3, 0($s2)

				# Mensagem de letra incorreta
				jal print_nova_linha
				la $a0, m_letra_errada
				jal print_string

				j final_bloco

			# Fim do bloco if-else
			final_bloco:
				j loop_jogo

		# Finaliza loop principal do jogo e volta para a main
		fim_loop_jogo:
			# Ler $ra da pilha
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			jr $ra
	
	# Verificar condições de finalização do jogo
	# Parâmetros:
	#   Contador de erros = $s3
	#   PIG = $s0
	verificar_fim_jogo:
		# Se erros == 6 -> finalizar jogo
		beq $s3, 6, fim_loop_jogo
		# Copiar a PIG para $t0
		move $t0, $s0

		li $t2, 95    #Caratere '_'
		# Loop para verificar se já acertou todas as letras da PIG
		loop_vfj:
			# Ler caractere da PIG
			lb $t1, 0($t0)
			# Se chegar no final da palavra -> finalizar jogo
			beqz $t1, fim_loop_jogo

			# Se caractere == '_' -> finalizar função e continuar o jogo
			beq $t1, $t2, fim_vfj

			# Incrementa ponteiro da palavra
			addi $t0, $t0, 1

			j loop_vfj

	# Finalizar função
	fim_vfj:
		jr $ra
	
	# Validar caractere digitado pelo jogador
	# Parâmetros:
	#   Caractere digitado = $t0
	validar_entrada:
		# Validar letras maiúsculas
		blt $t0, 65, entrada_invalida    # Caractere < 65 -> inválido
		ble $t0, 90, fim_ve              # Caractere <= 90 -> válido 

		# Validar letras minúsculas
		blt $t0, 97, entrada_invalida    # Caractere < 97 -> inválido
		bgt $t0, 122, entrada_invalida   # Caractere > 122 -> inválido
	
	# Finalizar função caso caractere seja válido
	fim_ve:
		# Se caractere não for maiúsculo, não converter para minúsculo
		blt $t0, 65, fim_conversao
		bgt $t0, 90, fim_conversao

		# Caso contrário -> converter para minúsculo
		addi $t0, $t0, 32

		fim_conversao:
			jr $ra

	# Lidar com entrada inválida digitada pelo jogador
	entrada_invalida:
		jal print_nova_linha
		la $a0, m_entrada_invalida
		jal print_string
		j inicio_solicitar_letra

	# Verificar se a palavra secreta contém o caractere digitado
	# Parâmetros:
	#   Caractere digitado = $t0
	#   Palavra secreta = $t1
	verificar_contem_letra:
		# Ler caractere da palavra
		lb $t2, 0($t1)
		# Se chegar no final da palavra -> não contém a letra digitada
		beqz $t2, inicio_nao_contem_letra

		# Se letra não for maiúscula -> pula conversão
		bgt $t2, 90, pula_conversao
		# Caso contrário -> converter para minúsculo
		addi $t2, $t2, 32

		pula_conversao:
		# Se o caractere digitado == caractere atual -> contém letra digitada
		beq $t0, $t2, inicio_contem_letra

		# Incrementa ponteiro da palavra
		addi $t1, $t1, 1

		j verificar_contem_letra
	
	# Atualizar PIG com a letra digitada nas lacunas correspondentes
	# Parâmetros:
	#   Caractere digitado = $t0
	#   PIG = $t1
	#   Palavra secreta = $t2
	atualizar_PIG:
		# Contador do offset = $t5
		li $t5, 0
		# Endereço do início da PIG = $t6
		move $t6, $t1

		# Loop para varre PIG e atualizar as posições necessárias
		loop_atualizar_PIG:
			# Ponteiro para varrer a palavra secreta = $t3
			lb $t3, 0($t2)
			# Ponteiro para varrer a PIG = $t4
			lb $t4, 0($t1)
			# Se chegar ao final da palavra secreta -> finaliza a função
			beqz $t3, fim_atualizar_PIG

			# Se letra não for maiúscula -> pula conversão
			bgt $t3, 90, pula_conversao2
			# Caso contrário -> converter para minúsculo
			addi $t3, $t3, 32

			pula_conversao2:
			# Se PIG[$t4] != '_' -> continuar loop
			bne $t4, 95, continuar_atualizar_PIG
			# Se caractere digitado != palavra secreta na posição $t3 -> continuar loop
			bne $t0, $t3, continuar_atualizar_PIG

			# Caso contrário -> PIG[$t5] = caractere digitado ($t0)
			add $t7, $t6, $t5    # $t7 = endereço_PIG + offset em bytes
			sb $t0, 0($t7)       # Atribuição

			continuar_atualizar_PIG:
			# Incrementa ponteiro da palavra secreta
			addi $t2, $t2, 1
			# Incrementa ponteiro da PIG
			addi $t1, $t1, 1
			# Incrementa contador do offset
			addi $t5, $t5, 1

			j loop_atualizar_PIG
	
	# Finalizar função
	fim_atualizar_PIG:
		jr $ra
	
	# Operações para finalização do jogo
	# Parâmetros:
	#   Contador de erros = $s3
	finalizar_jogo:
		jal print_nova_linha

		# Se erros == 6 -> Bloco da derrota
		beq $s3, 6, bloco_derrota

		# Caso contrário -> Mensagem de vitória
		la $a0, m_acertou_palavra
		jal print_string
		j fim_fj

		# Printar mensagem de derrota e carregar palavra secreta
		bloco_derrota:
			# Mensagem de derrota
			la $a0, m_deu_forca
			jal print_string
			la $a0, 0($s6)
			jal print_string
	
	# Finalizar função
	fim_fj:
		jr $ra
	
	# Finalizar o programa
	fim_programa:
		li $v0, 10
		syscall
	
	# Printar string na linha de comando
	# Parâmetros:
	#   String a ser printada = $a0
	print_string:
		li $v0, 4
		syscall
		jr $ra
	
	# Printar /n na linha de comando
	print_nova_linha:
		la $a0, pula_linha
		li $v0, 4
		syscall
		jr $ra

	# Ler caractere digitado na linha de comando
	# Retorna:
	#   Caractere digitado = $v0
	ler_caractere:
		li $v0, 12
		syscall
		jr $ra
