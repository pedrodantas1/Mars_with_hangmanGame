.data
	m_pede_letra: .asciiz "Digite uma letra = "
	m_entrada_invalida: .asciiz "Entrada inválida.\n"
	m_letra_certa: .asciiz "Muito bem!"
	m_letra_errada: .asciiz "A palavra não contêm essa letra."
	m_deu_forca: .asciiz "Que pena! Deu forca e a palavra secreta era X"
	m_acertou_palavra: .asciiz "Parabéns! Você acertou a palavra secreta."

	palavra_secreta: .asciiz "Estados Unidos"
	

	pula_linha: .asciiz "\n"
	status: .asciiz "CEF"


	# variaveis
	# palavra secreta = $s6
	# PIG = $s0 -> endereço 0x10000000
	# tamanho da palavra = $s5
	# status do game = $s4 -> endereço 0x10010500
	
.text
	# Endereço de memoria base para o jogo
	lui $s0, 0x1000
	# Endereço de memoria base para o status do game
	li $s4, 0x10010500
	
	# Flag de carregar palavra
	la $t0, status
	lb $t1, 0($t0)
	sb $t1, 0($s4)
	# Iniciar contador do tamanho da palavra
	li $s5, 0

	# Carregar palavra secreta
	la $s6, palavra_secreta
	jal carregar_palavra_secreta

	# Definir lacunas da palavra secreta
	# Copiar palavra para $t1
	move $t1, $s6
	jal criar_mascara_palavra

	# Iniciar jogo
	# Flag de inicio de jogo
	la $t0, status
	lb $t1, 1($t0)
	sb $t1, 0($s4)
	jal iniciar_jogo


	jal fim_programa

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
	
	# Variáveis
	# Contador de erros = $t7
	iniciar_jogo:
		# Iniciar contador de erros
		li $t7, 0

		loop_jogo:
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
				# Atualiza PIG
			
			inicio_nao_contem_letra:
				# Incrementa contador de erros
				# Mensagem de letra errada
				# Atualiza boneco da forca

			j loop_jogo

			fim_loop_jogo:
				jr $ra
	
	verificar_fim_jogo:
		# Se erros == 6, finaliza o jogo
		beq $t7, 6, fim_loop_jogo
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
	# 	subi $t0, $t0, 32

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