package mars.tools;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
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
	 * Simple constructor, likely used to run a stand-alone memory reference
	 * visualizer.
	 * 
	 * @param title   String containing title for title bar
	 * @param heading String containing text for heading shown in upper part of
	 *                window.
	 */
	public JogoDaForca(String title, String heading) {
		super(title, heading);
	}

	/**
	 * Simple constructor, likely used by the MARS Tools menu mechanism
	 */
	public JogoDaForca() {
		super(heading + version, heading);
	}

	/**
	 * Main provided for pure stand-alone use. Recommended stand-alone use is to
	 * write a
	 * driver program that instantiates a MemoryReferenceVisualization object then
	 * invokes its go() method.
	 * "stand-alone" means it is not invoked from the MARS Tools menu. "Pure" means
	 * there
	 * is no driver program to invoke the application.
	 */
	public static void main(String[] args) {
		new JogoDaForca(heading + version, heading).go();
	}

	/**
	 * Required method to return Tool name.
	 * 
	 * @return Tool name. MARS will display this in menu item.
	 */
	public String getName() {
		return "Jogo da Forca";
	}

	protected JComponent getHelpComponent() {
		final String helpContent = 
			"Para rodar o app corretamente é necessário abrir o arquivo .jar por\n" +
			"alguma linha de comando da sua preferência.\n" +
			"Para isso, primeiro você deve acessar a pasta onde se encontra o arquivo\n" +
			"pela linha de comando usando o comando \"cd caminho_da_pasta\" sem as aspas.\n" +
			"Logo após isso, execute o comando \"java -jar JogoDaForca.jar\".\n" +
			"Depois que o app for aberto clique no botão \"Open MIPS program e\"\n" +
			"selecione o arquivo \"game.asm\" que carrega o código assembly do jogo.\n" +
			"Agora é só iniciar o jogo clicando no botão \"Assemble and run\" e seguir\n" +
			"os comandos que aparecerem na linha de comando para dar continuidade\n" +
			"ao jogo.\n\n" +
			"Caso queira editar as palavras que fazem parte do banco de dados do\n" +
			"jogo é necessário editar o arquivo \"palavras.txt\".\n" +
			"Você pode remover as palavras existentes ou adicionar as palavras da sua\n" +
			"preferência, sendo cada palavra em uma linha e respeitando o limite\n" +
			"de 31 caracteres por palavra. Também é preciso alterar a variável\n" +
			"'qtd_palavras' que fica logo no início do arquivo \"game.asm\" e colocar\n" +
			"o valor correspondente ao número atual de palavras (ou linhas) existentes\n" +
			"no arquivo \"palavras.txt\". Lembre de salvar os arquivos.\n" +
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
	 * Implementation of the inherited abstract method to build the main
	 * display area of the GUI. It will be placed in the CENTER area of a
	 * BorderLayout. The title is in the NORTH area, and the controls are
	 * in the SOUTH area.
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
				updateGameStatus(value);
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
	 * Atualizar o status do game para auxiliar na construção da interface.
	 * 
	 * @param value Flag de status atual do game.
	 */
	private void updateGameStatus(int value){
		if (value != CARREGANDO_PALAVRA && value != JOGO_EM_EXECUCAO && value != FIM_DE_JOGO)
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
	 * 
	 * @return Dimension do tamanho do display pré-definido.
	 */
	private Dimension getDisplayAreaDimension() {
		return new Dimension(displayWidth, displayHeight);
	}

	protected void updateDisplay() {
		canvas.repaint();
	}

	protected void initializePostGUI() {
		setDefaultAddresses();
		imgForca = "Forca.jpg";
		statusGame = PRE_GAME;
	}

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

			//Desenhar background do jogo
			paintBackground(g2d);
			//Desenhar textos do jogo
			if (secretMask != null)
				paintText(g2d);
		}

		private void paintBackground(Graphics2D g2d){
			System.setProperty("sun.java2d.translaccel", "true");
			Image img = new ImageIcon(getClass().getResource(Globals.imagesPath + imgForca)).getImage();
			Dimension size = getSize();
			g2d.drawImage(img, 0, 0, size.width, size.height, null);
		}

		private void paintText(Graphics2D g2d){
			Dimension size = getSize();
			Font font = new Font("Verdana", Font.BOLD, 24);
			g2d.setFont(font);
			g2d.setColor(Color.blue);
			String word = "";
			for (int i=0; i<secretMask.length(); i++){
				word += secretMask.charAt(i);
				if (i != secretMask.length()-1){
					word += " ";
				}
			}
			g2d.drawString(word, (size.width/2)-70, size.height/2);
			
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