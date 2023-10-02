.data
	m_pede_letra: .asciiz "Digite uma letra = "
	m_entrada_invalida: .asciiz "Entrada inv�lida.\n"
	m_letra_certa: .asciiz "Muito bem! Letra correta.\n"
	m_letra_errada: .asciiz "Ops! A palavra n�o cont�m essa letra.\n"
	m_deu_forca: .asciiz "Que pena! Deu forca e a palavra secreta era: "
	m_acertou_palavra: .asciiz "Parab�ns! Voc� acertou a palavra secreta.\n"
	pula_linha: .asciiz "\n"

	palavra_secreta: .asciiz "Estados Unidos"

	# Vari�veis
	# Palavra secreta = $s6
	# Palavra in-game (PIG) = $s0 -> endere�o 0x10000000
	# Tamanho da palavra = $s5
	# Status do game = $s4 -> endere�o 0x10010500
	# Contador de erros = $s3
	
.text
	# Endere�o de memoria base para o jogo
	lui $s0, 0x1000
	# Endere�o de memoria base para o status do game
	li $s4, 0x10010500
	
	# Iniciar contador do tamanho da palavra
	li $s5, 0

	# Carregar palavra secreta
	la $s6, palavra_secreta
	jal carregar_palavra_secreta

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
		# Carrega o caractere da posi��o atual da palavra em $t2
		lb $t2, 0($t1)
		beqz $t2, fim_cmp

		# Compara��es
		li $t3, 45    #Caratere '-'
		beq $t2, $t3, copiar_caractere

		li $t3, 32    #Caratere espa�o
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
			# Se n�o houver nenhum '_' na palavra, finaliza o jogo
			lb $t1, 0($t0)
			beqz $t1, fim_loop_jogo

			# Verifica se � igual a '_'
			beq $t1, $t2, fim_vfj

			# Incrementa ponteiro da palavra
			addi $t0, $t0, 1

			j loop_vfj

		fim_vfj:
			jr $ra
	
	# Caractere digitado = $t0
	validar_entrada:
		# Se valor do caractere estiver entre 65 e 90 (letras mai�sculas)
		blt $t0, 65, entrada_invalida
		ble $t0, 90, fim_ve

		# Se valor do caractere estiver entre 97 e 122 (letras min�sculas)
		blt $t0, 97, entrada_invalida
		bgt $t0, 122, entrada_invalida
		
		fim_ve:
			# Converter para min�sculo se necess�rio
			# Se n�o for mai�sculo, n�o precisa fazer nada
			blt $t0, 65, fim_conversao
			bgt $t0, 90, fim_conversao

			# Caso contr�rio, converter para min�sculo
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
	# 	# Se n�o for mai�sculo, n�o precisa fazer nada
	# 	blt $t0, 65, fim_cem
	# 	bgt $t0, 90, fim_cem

	# 	# Caso contr�rio, converter para min�sculo
	# 	addi $t0, $t0, 32

	# 	fim_cem:
	# 		jr $ra

	# Caractere digitado = $t0
	# Palavra secreta = $t1
	verificar_contem_letra:
		# Ponteiro para varrer a palavra = $t2
		lb $t2, 0($t1)
		beqz $t2, inicio_nao_contem_letra

		# Converter para min�sculo se necess�rio
		# Se n�o for mai�sculo, n�o precisa fazer nada
		bgt $t2, 90, pula_conversao

		# Caso contr�rio, converter para min�sculo
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

			# Converter para min�sculo se necess�rio
			bgt $t3, 90, pula_conversao_2
			# Caso contr�rio, converter para min�sculo
			addi $t3, $t3, 32

			pula_conversao_2:
			# Se caractere da PIG na posi�ao $t4 != '_'
			bne $t4, 95, continuar_atualizar_PIG
			# Se caractere digitado != caractere na posicao $t3
			bne $t0, $t3, continuar_atualizar_PIG

			# Caso contr�rio atribuir o caractere digitado em PIG[$t5]
			# Calcular endere�o de memoria da posicao especifica da PIG
			add $t7, $t6, $t5    # $t7 = endPIG + offset em bytes

			# Atribui��o
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

		# Caso contr�rio, executar bloco da vit�ria
		# Mensagem de vit�ria
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
