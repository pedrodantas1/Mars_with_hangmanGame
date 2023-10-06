.data
	m_pede_letra: .asciiz "Digite uma letra = "
	m_entrada_invalida: .asciiz "Entrada inválida.\n"
	m_letra_certa: .asciiz "Muito bem! Letra correta.\n"
	m_letra_errada: .asciiz "Ops! A palavra não contém essa letra.\n"
	m_deu_forca: .asciiz "Que pena! Deu forca e a palavra secreta era: "
	m_acertou_palavra: .asciiz "Parabéns! Você acertou a palavra secreta.\n"
	m_erro_abrir_arquivo: .asciiz "\nErro ao abrir arquivo.\n"
	m_erro_ler_arquivo: .asciiz "\nErro ao ler arquivo.\n"
	pula_linha: .asciiz "\n"

	# palavra_secreta: .asciiz "Estados Unidos"
	arquivo: .asciiz "palavras.txt"
	qtd_palavras: .word 4
	buffer: .space 1
	linha: .space 64

	# Variáveis
	# Palavra secreta = $s6
	# Palavra in-game (PIG) = $s0 -> endereço 0x10000000
	# Tamanho da palavra = $s5
	# Status do game = $s4 -> endereço 0x10010500
	# Contador de erros = $s3
	# Contador de erros auxiliar para interface = $s2 -> endereço 0x10010600
	
.text
	# Endereço de memoria base para o jogo
	lui $s0, 0x1000
	# Endereço de memoria base para o status do game
	li $s4, 0x10010500
	# Endereço de memoria base para o contador auxiliar
	li $s2, 0x10010600

	# Carregar palavra secreta pré-definida
	# la $s6, palavra_secreta
	# jal carregar_palavra_secreta

	# Carregar palavra secreta aleatória do arquivo
	jal abrir_arquivo			 # $s7 = file descriptor
	# Gerar número aleatório (entre 0 e qtd_palavras-1)
	jal gerar_numero_aleatorio   # $a0 = número aleatório
	# $s5 = tamanho da palavra
	# $s6 = palavra secreta
	jal ler_palavra

	# Flag de carregar palavra
	li $t1, 1
	sw $t1, 0($s4)
	# Definir lacunas da palavra secreta
	# Copiar palavra para $t1
	move $t1, $s6
	jal criar_mascara_palavra

	# Iniciar jogo
	# Flag de inicio de jogo
	li $t1, 2
	sw $t1, 0($s4)
	jal iniciar_jogo

	# Finalizar jogo
	# Flag de fim de jogo
	li $t1, 3
	sw $t1, 0($s4)
	jal finalizar_jogo

	jal fim_programa

	gerar_numero_aleatorio:
		li $v0, 42
		li $a0, 74
		la $t0, qtd_palavras
		lw $a1, 0($t0)
		syscall
		jr $ra

	abrir_arquivo:
		li $v0, 13
		la $a0, arquivo
		li $a1, 0
		li $a2, 0
		syscall
		bltz $v0, erro_abrir_arquivo
		move $s7, $v0
		jr $ra
	
	erro_abrir_arquivo:
		la $a0, m_erro_abrir_arquivo
		jal print_string
		j fim_programa
	
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
			syscall			# Byte salvo no endereço armazenado em $t0

			# Parar de ler quando número de bytes lidos for <= 0
			blez $v0 fim_ler_palavra

			# Se quantidade de bytes da linha exceder 64, finalizar função
			slti $t3, $t2, 64
			beqz $t3, fim_ler_palavra

			# Se byte lido for \n, verificar se vai ler próxima linha ou se essa é a palavra sorteada
			lb $t4, 0($t0)         #Byte lido = $t4
			beq $t4, 10, consumir_linha

			# Caso contrário, concatenar byte na linha
			add $t5, $t1, $t2      # ponteiro para linha = endereço inicial da linha + tamanho atual da linha
			sb $t4, 0($t5)         # Salvar byte na posição do ponteiro

			# Incrementar contador do tamanho da linha
			addi $t2, $t2, 1

			j loop_ler_palavra

		consumir_linha:
			# Colocar \0 no final da linha
			add $t5, $t1, $t2
			sb $zero 0($t5)
			# Se for a palavra sorteada, finaliza o laço
			beq $t6, $t7, fim_ler_palavra
			# Caso contrário, ler próxima linha
			# Incrementa contador da linha
			addi $t6, $t6, 1
			# Reseta contador do tamanho da linha
			li $t2, 0
			j loop_ler_palavra

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

	carregar_palavra_secreta:
		lb $t0, 0($s6)
		beqz $t0, fim_cps
		# Incrementa tamanho da palavra
		addi $s5, $s5, 1
		# Incrementa ponteiro da palavra
		addi $s6, $s6, 1

		j carregar_palavra_secreta

		fim_cps:
			sub $s6, $s6, $s5
			jr $ra
	
	criar_mascara_palavra:
		# Carrega o caractere da posição atual da palavra em $t2
		lb $t2, 0($t1)
		beqz $t2, fim_cmp

		# Comparações
		li $t3, 45    #Caratere '-'
		beq $t2, $t3, copiar_caractere

		li $t3, 32    #Caratere espaço
		beq $t2, $t3, copiar_caractere

		li $t2, 95    #Caratere '_'

		copiar_caractere:
			sb $t2, 0($s0)
			# Incrementa ponteiro da palavra
			addi $t1, $t1, 1
			# Incrementa ponteiro da mascara
			addi $s0, $s0, 1

		j criar_mascara_palavra

		fim_cmp:
			sub $s0, $s0, $s5
			jr $ra
	
	# Contador de erros = $s3
	# Contador de erros auxiliar = $s2
	iniciar_jogo:
		# Salvar $ra na pilha
		addi $sp, $sp, -4
		sw $ra, 0($sp)

		# Iniciar contador de erros
		li $s3, 0

		loop_jogo:
			# Verificar se o jogo finalizou
			jal verificar_fim_jogo
			# Solicitar letra
			inicio_solicitar_letra:
				la $a0, m_pede_letra
				jal print_string
				jal ler_caractere
				move $t0, $v0        # $t0 = caractere digitado

			# Validar entrada
			jal validar_entrada

			# Verificar se a palavra secreta contem o caractere digitado
			# Copiar palavra para $t1
			move $t1, $s6
			jal verificar_contem_letra

			inicio_contem_letra:
				# Mensagem de letra correta
				jal print_nova_linha
				la $a0, m_letra_certa
				jal print_string
				# Atualizar PIG
				move $t1, $s0
				move $t2, $s6
				jal atualizar_PIG
				j final_bloco
			
			inicio_nao_contem_letra:
				# Incrementar contador de erros
				addi $s3, $s3, 1
				# Atualizar contador auxiliar para refletir na interface
				sw $s3, 0($s2)
				# Mensagem de letra errada
				jal print_nova_linha
				la $a0, m_letra_errada
				jal print_string
				# Atualizar boneco da forca

				j final_bloco

			final_bloco:
				j loop_jogo

			fim_loop_jogo:
				# Ler $ra da pilha
				lw $ra, 0($sp)
				addi $sp, $sp, 4
				jr $ra
	
	verificar_fim_jogo:
		# Se erros == 6, finaliza o jogo
		beq $s3, 6, fim_loop_jogo
		# Copiar a PIG para $t0
		move $t0, $s0
		li $t2, 95    #Caratere '_'
		loop_vfj:
			# Se não houver nenhum '_' na palavra, finaliza o jogo
			lb $t1, 0($t0)
			beqz $t1, fim_loop_jogo

			# Verifica se é igual a '_'
			beq $t1, $t2, fim_vfj

			# Incrementa ponteiro da palavra
			addi $t0, $t0, 1

			j loop_vfj

		fim_vfj:
			jr $ra
	
	# Caractere digitado = $t0
	validar_entrada:
		# Se valor do caractere estiver entre 65 e 90 (letras maiúsculas)
		blt $t0, 65, entrada_invalida
		ble $t0, 90, fim_ve

		# Se valor do caractere estiver entre 97 e 122 (letras minúsculas)
		blt $t0, 97, entrada_invalida
		bgt $t0, 122, entrada_invalida
		
		fim_ve:
			# Converter para minúsculo se necessário
			# Se não for maiúsculo, não precisa fazer nada
			blt $t0, 65, fim_conversao
			bgt $t0, 90, fim_conversao

			# Caso contrário, converter para minúsculo
			addi $t0, $t0, 32

			fim_conversao:
				jr $ra

	entrada_invalida:
		jal print_nova_linha
		la $a0, m_entrada_invalida
		jal print_string
		j inicio_solicitar_letra
	
	# Caractere = $t0
	# converte_em_minusculo:
	# 	# Se não for maiúsculo, não precisa fazer nada
	# 	blt $t0, 65, fim_cem
	# 	bgt $t0, 90, fim_cem

	# 	# Caso contrário, converter para minúsculo
	# 	addi $t0, $t0, 32

	# 	fim_cem:
	# 		jr $ra

	# Caractere digitado = $t0
	# Palavra secreta = $t1
	verificar_contem_letra:
		# Ponteiro para varrer a palavra = $t2
		lb $t2, 0($t1)
		beqz $t2, inicio_nao_contem_letra

		# Converter para minúsculo se necessário
		# Se não for maiúsculo, não precisa fazer nada
		bgt $t2, 90, pula_conversao

		# Caso contrário, converter para minúsculo
		addi $t2, $t2, 32

		pula_conversao:
		# Se o caractere digitado == caractere atual
		beq $t0, $t2, inicio_contem_letra

		# Incrementa ponteiro da palavra
		addi $t1, $t1, 1

		j verificar_contem_letra
	
	# Caractere digitado = $t0
	# PIG = $t1
	# Palavra secreta = $t2
	atualizar_PIG:
		# Contador = $t5
		li $t5, 0
		# Guardar inicio da PIG = $t6
		move $t6, $t1
		loop_atualizar_PIG:
			# Ponteiro para varrer a palavra secreta = $t3
			lb $t3, 0($t2)
			# Ponteiro para varrer a PIG = $t4
			lb $t4, 0($t1)
			beqz $t3, fim_atualizar_PIG

			# Converter para minúsculo se necessário
			bgt $t3, 90, pula_conversao_2
			# Caso contr?rio, converter para minúsculo
			addi $t3, $t3, 32

			pula_conversao_2:
			# Se caractere da PIG na posição $t4 != '_'
			bne $t4, 95, continuar_atualizar_PIG
			# Se caractere digitado != caractere na posição $t3
			bne $t0, $t3, continuar_atualizar_PIG

			# Caso contrário atribuir o caractere digitado em PIG[$t5]
			# Calcular endereço de memoria da posicao especifica da PIG
			add $t7, $t6, $t5    # $t7 = endPIG + offset em bytes

			# Atribuição
			sb $t0, 0($t7)

			continuar_atualizar_PIG:
			# Incrementa ponteiro da palavra secreta
			addi $t2, $t2, 1
			# Incrementa ponteiro da PIG
			addi $t1, $t1, 1
			# Incrementa contador
			addi $t5, $t5, 1

			j loop_atualizar_PIG
	
		fim_atualizar_PIG:
			jr $ra
	
	# Contador de erros = $s3
	finalizar_jogo:
		jal print_nova_linha
		# Se erros == 6, ir para o bloco da derrota
		beq $s3, 6, bloco_derrota

		# Caso contrário, executar bloco da vitória
		# Mensagem de vitória
		la $a0, m_acertou_palavra
		j fim_fj

		bloco_derrota:
			# Mensagem de derrota
			la $a0, m_deu_forca
			jal print_string
			la $a0, 0($s6)
		
		fim_fj:
			jal print_string
			jr $ra
	
	fim_programa:
		li $v0, 10
		syscall
	
	print_string:
		li $v0, 4
		syscall
		jr $ra
	
	print_nova_linha:
		la $a0, pula_linha
		li $v0, 4
		syscall
		jr $ra

	ler_caractere:
		li $v0, 12
		syscall
		jr $ra

	print_caractere:
		li $v0, 11
		syscall
		jr $ra
