package mars.tools;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.RenderingHints;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.Observable;

import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JComponent;
import javax.swing.JOptionPane;
import javax.swing.JPanel;

import mars.Globals;
import mars.mips.hardware.AccessNotice;
import mars.mips.hardware.Memory;
import mars.mips.hardware.MemoryAccessNotice;

/*
Copyright (c) 2003-2006,  Pete Sanderson and Kenneth Vollmar

Developed by Pete Sanderson (psanderson@otterbein.edu)
and Kenneth Vollmar (kenvollmar@missouristate.edu)

Permission is hereby granted, free of charge, to any person obtaining 
a copy of this software and associated documentation files (the 
"Software"), to deal in the Software without restriction, including 
without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject 
to the following conditions:

The above copyright notice and this permission notice shall be 
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

(MIT license, http://www.opensource.org/licenses/mit-license.html)
 */

/**
 * Implementação do jogo da forca usando o MARS para rodar algoritmo
 * base do jogo construído em assembly MIPS.
 */
public class JogoDaForca extends AbstractMarsToolAndApplication {
	private static String heading = "Jogo da Forca";
	private static String version = " V1.0";
	private static int displayWidth = 650;
	private static int displayHeight = 350;

	public static final int PRE_GAME = 0;
	public static final int CARREGANDO_PALAVRA = 1;
	public static final int JOGO_EM_EXECUCAO = 2;
	public static final int FIM_DE_JOGO = 3;

	private JPanel canvas;
	private String imgForca;

	private String baseAddress;
	private String statusAddress;
	private String errorsAddress;

	private String secretWord;
	private String secretMask;
	private int statusGame;

	/**
	 * Construtor básico.
	 * 
	 * @param title   String contendo o título da janela.
	 * @param heading String contendo o texto a ser mostrado no header do app.
	 */
	public JogoDaForca(String title, String heading) {
		super(title, heading);
	}

	/**
	 * Construtor básico com título e header pré-definidos.
	 */
	public JogoDaForca() {
		super(heading + version, heading);
	}

	/**
	 * Função de inicialização do app stand-alone.
	 */
	public static void main(String[] args) {
		new JogoDaForca(heading + version, heading).go();
	}

	/**
	 * Método para retornar o nome do app.
	 * 
	 * @return Nome do app a ser mostrado na barra de tools do mars padrão.
	 */
	public String getName() {
		return "Jogo da Forca";
	}

	/**
	 * Janela de ajuda que é aberta ao clicar no botão help.
	 */
	protected JComponent getHelpComponent() {
		final String helpContent = 
			"Para rodar o app corretamente é necessário abrir o arquivo .jar por\n" +
			"alguma linha de comando da sua preferência.\n" +
			"Para isso, primeiro você deve acessar a pasta onde se encontra o arquivo\n" +
			"pela linha de comando usando o comando \"cd caminho_da_pasta\" sem as aspas.\n" +
			"Logo após isso, execute o comando \"java -jar JogoDaForca.jar\".\n" +
			"Depois que o app for aberto clique no botão \"Open MIPS program e selecione\"\n" +
			"o arquivo \"game.asm\" que carrega o código assembly do jogo. Agora é só\n" +
			"iniciar o jogo clicando no botão \"Assemble and run\" e seguir os comandos\n" +
			"que aparecerem na linha de comando para dar continuidade à jogatina.\n\n" +
			"Caso deseje editar as palavras que fazem parte do banco de dados do\n" +
			"jogo é necessário editar o arquivo \"palavras.txt\".\n" +
			"Você pode remover as palavras existentes ou adicionar as palavras da sua\n" +
			"preferência, sendo cada palavra em uma linha (sem acentos ou cedilha) e\n" +
			"respeitando o limite de 31 caracteres por palavra. Também é preciso alterar\n" +
			"a variável 'qtd_palavras' que fica logo no início do arquivo \"game.asm\" e\n" +
			"colocar o valor correspondente ao número atual de palavras (ou linhas)\n" +
			"existentes no arquivo \"palavras.txt\". Lembre-se de salvar os arquivos.\n" +
			"Espero que você se divirta muito com este jogo que, apesar de desenvolvido\n" +
			"com simplicidade, foi criado para relembrar os velhos tempos.\n\n" +
			">> Programa desenvolvido para um trabalho da disciplina de Organização e\n" +
			"Arquitetura de Computadores da Universidade Federal de Sergipe (UFS/DSI).\n";
		JButton help = new JButton("Help");
		help.addActionListener(
			new ActionListener() {
				public void actionPerformed(ActionEvent e) {
					JOptionPane.showMessageDialog(theWindow, helpContent);
				}
			}
		);
		return help;
	}

	/**
	 * Método para construir a estrutura central da janela. Será posicionada
	 * no centro, sendo que o título ficará em cima e os controles em baixo.
	 */
	protected JComponent buildMainDisplayArea() {
		JPanel main = new JPanel();
		main.add(buildGameArea());
		return main;
	}

	/**
	 * Método sobrecarregado que detecta as instruções de leitura e escrita em
	 * registradores. Realiza toda a lógica de atualização da interface de
	 * acordo com os comando executados em registradores nos endereços
	 * pré-definidos.
	 */
	protected void processMIPSUpdate(Observable resource, AccessNotice notice) {
		if (!notice.accessIsFromMIPS())
			return;
		MemoryAccessNotice info = (MemoryAccessNotice) notice;
		int address = info.getAddress();
		int value = info.getValue();
		//Para comando de escrita em registrador
		if (notice.getAccessType() == AccessNotice.WRITE) {
			String end = Integer.toHexString(address);
			//Se atualizar status no endereço designado
			if (end.equals(statusAddress)){
				setGameStatus(value);
				return;
			}
			//Executar comando de acordo com o status do jogo
			if (statusGame == CARREGANDO_PALAVRA){
				loadWordMask(info);
			}else if (statusGame == JOGO_EM_EXECUCAO){
				//Para escrita no registrador da PIG
				if (end.substring(0, 4).equals(baseAddress.substring(0, 4))){
					updateSecretMask(info);
				}else if (end.equals(errorsAddress)){  //Para escrita no registrador do contador de erros auxiliar
					imgForca = "Forca" + value + ".jpg";
				}
			}
		}else{  //Para comando de leitura em registrador
			if (statusGame == CARREGANDO_PALAVRA){
				loadSecretWord(info);
			}
		}
	}

	/**
	 * Definir o status do game para auxiliar na construção da interface.
	 * 
	 * @param value Flag de status atual do game.
	 */
	private void setGameStatus(int value){
		if (value != PRE_GAME &&
			value != CARREGANDO_PALAVRA &&
			value != JOGO_EM_EXECUCAO &&
			value != FIM_DE_JOGO)
			return;

		statusGame = value;
	}

	/**
	 * Carregar máscara da palavra secreta quando inicia o jogo.
	 * 
	 * @param notice Informações sobre a instrução executada.
	 */
	private void loadWordMask(MemoryAccessNotice notice) {
		if (secretMask == null){
			secretMask = "";
		}
		int value = notice.getValue();
		if (value != 0){
			secretMask += Character.toString(value);
		}
	}

	/**
	 * Carregar palavra secreta quando inicia o jogo.
	 * 
	 * @param notice Informações sobre a instrução executada.
	 */
	private void loadSecretWord(MemoryAccessNotice notice) {
		if (secretWord == null){
			secretWord = "";
		}
		int value = notice.getValue();
		if (value != 0){
			secretWord += Character.toString(value);
		}
	}

	/**
	 * Atualizar máscara da palavra secreta com as letras correspondentes.
	 * 
	 * @param notice Informações sobre a instrução executada.
	 */
	private void updateSecretMask(MemoryAccessNotice notice) {
		int address = notice.getAddress();
		int offset = address - Integer.parseInt(baseAddress, 16);
		//Substituir letra na posição
		char[] arr = secretMask.toCharArray();
		arr[offset] = secretWord.charAt(offset);
		secretMask = new String(arr);
	}

	/**
	 * Definir endereços base para funcionamento do jogo.
	 */
	private void setDefaultAddresses() {
		baseAddress = Integer.toHexString(Memory.dataSegmentBaseAddress);
		statusAddress = "10010500";
		errorsAddress = "10010600";
	}

	/**
	 * Construir área de gráficos destinada ao jogo.
	 */
	private JComponent buildGameArea() {
		canvas = new GraphicsPanel();
		canvas.setPreferredSize(getDisplayAreaDimension());
		return canvas;
	}

	/**
	 * Retornar um objeto Dimension com o tamanho da janela definido.
	 * 
	 * @return Dimension do tamanho do display pré-definido.
	 */
	private Dimension getDisplayAreaDimension() {
		return new Dimension(displayWidth, displayHeight);
	}

	/**
	 * Atualizar a janela após a execução de cada instrução do programa MIPS.
	 */
	protected void updateDisplay() {
		canvas.repaint();
	}

	/**
	 * Inicializar variáveis após a construção da interface principal.
	 */
	protected void initializePostGUI() {
		setDefaultAddresses();
		setGameStatus(PRE_GAME);
		imgForca = "Forca.jpg";
	}

	/**
	 * Método para resetar estruturas do app. É chamado ao clicar no botão reset.
	 */
	protected void reset() {
		secretMask = "";
		secretWord = "";
		imgForca = "Forca.jpg";
		statusGame = PRE_GAME;
		updateDisplay();
	}

	/**
	 * Classe privada para representar a parte gráfica do jogo.
	 */
	private class GraphicsPanel extends JPanel {
		public void paint(Graphics g) {
			var g2d = (Graphics2D) g;
			var rh = new RenderingHints(
					RenderingHints.KEY_ANTIALIASING,
					RenderingHints.VALUE_ANTIALIAS_ON);
			rh.put(RenderingHints.KEY_RENDERING,
					RenderingHints.VALUE_RENDER_QUALITY);
			g2d.setRenderingHints(rh);

			paintBackground(g2d);
			if (secretMask != null)
				paintText(g2d);
		}

		/**
		 * Método para pintar a imagem de fundo do game.
		 * 
		 * @param g2d Objeto de configuração de gráficos.
		 */
		private void paintBackground(Graphics2D g2d){
			System.setProperty("sun.java2d.translaccel", "true");
			Image img = new ImageIcon(getClass().getResource(Globals.imagesPath + imgForca)).getImage();
			Dimension size = getSize();
			g2d.drawImage(img, 0, 0, size.width, size.height, null);
		}

		/**
		 * Método para desenhar os textos do app.
		 * 
		 * @param g2d Objeto de configuração de gráficos.
		 */
		private void paintText(Graphics2D g2d){
			Dimension size = getSize();
			Font font = new Font("Verdana", Font.BOLD, 24);
			g2d.setFont(font);
			g2d.setColor(Color.blue);

			//Construir palavra in-game
			String word = "";
			for (int i=0; i<secretMask.length(); i++){
				word += secretMask.charAt(i);
				if (i != secretMask.length()-1){
					word += " ";
				}
			}
			//Desenhar palavra in-game
			FontMetrics fm = g2d.getFontMetrics(font);
			int largura = fm.stringWidth(word);
			int posX = (size.width/2)-(largura/2);
			int posY = size.height/2;
			if (word.length() <= 32){
				int offset = 40;
				if (word.length() > 24)
					offset = 70;
				g2d.drawString(word, posX+offset, posY);
			}else{
				String firstLine = word.substring(0,32);
				String secondLine = word.substring(32);

				largura = fm.stringWidth(firstLine);
				posX = (size.width/2)-(largura/2)+70;
				g2d.drawString(firstLine, posX, posY);

				largura = fm.stringWidth(secondLine);
				posX = (size.width/2)-(largura/2)+70;
				g2d.drawString(secondLine, posX, posY+50);
			}
			//Aviso ao finalizar o jogo
			if (statusGame == FIM_DE_JOGO){
				g2d.setFont(new Font("Verdana", Font.BOLD, 18));
				if (secretWord.equals(secretMask)){  //Jogador venceu
					g2d.setColor(Color.green);
					g2d.drawString("Parabéns! Você acertou a palavra secreta", 20, size.height-50);
				}else{  //Jogador perdeu
					g2d.setColor(Color.red);
					g2d.drawString("Fim de jogo! A palavra era: " + secretWord, 20, size.height-50);
				}
				g2d.setFont(new Font("Verdana", Font.BOLD, 14));
				g2d.drawString("Aperte em stop, reset e depois em assemble and run para jogar novamente.", 20, size.height-20);
			}
		}
	}
}