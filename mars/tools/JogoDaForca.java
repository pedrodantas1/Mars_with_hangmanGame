package mars.tools;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.RenderingHints;
import java.util.Observable;

import javax.swing.ImageIcon;
import javax.swing.JComponent;
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
 * O jogo da forca do MarsTools!
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
					updateGame(info);
				}else if (end.equals(errorsAddress)){  //Para escrita no registrador do contador de erros aux
					imgForca = "Forca" + value + ".jpg";
				}
			}else if (statusGame == FIM_DE_JOGO){

			}
		}else{  //Para comando de leitura em registrador
			if (statusGame == CARREGANDO_PALAVRA){
				loadSecretWord(info);
			}
		}
	}

	void updateGameStatus(int value){
		if (value != CARREGANDO_PALAVRA && value != JOGO_EM_EXECUCAO && value != FIM_DE_JOGO)
			return;
		statusGame = value;
	}

	/**
	 * Carregar máscara da palavra secreta quando inicia o jogo
	 */
	void loadWordMask(MemoryAccessNotice notice) {
		if (secretMask == null){
			secretMask = "";
		}
		int value = notice.getValue();
		if (value != 0){
			secretMask += Character.toString(value);
		}
	}

	/**
	 * Carregar palavra secreta quando inicia o jogo
	 */
	void loadSecretWord(MemoryAccessNotice notice) {
		if (secretWord == null){
			secretWord = "";
		}
		int value = notice.getValue();
		if (value != 0){
			secretWord += Character.toString(value);
		}
	}

	void updateGame(MemoryAccessNotice notice) {
		int address = notice.getAddress();
		int offset = address - Integer.parseInt(baseAddress, 16);
		//Substituir letra na posição
		char[] arr = secretMask.toCharArray();
		arr[offset] = secretWord.charAt(offset);
		secretMask = new String(arr);
	}

	protected void updateDisplay() {
		canvas.repaint();
	}

	protected void initializePostGUI() {
		updateDefaultAddress();
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

	private void updateDefaultAddress() {
		baseAddress = Integer.toHexString(Memory.dataSegmentBaseAddress);
		statusAddress = "10010500";
		errorsAddress = "10010600";
	}

	private JComponent buildGameArea() {
		canvas = new GraphicsPanel();
		canvas.setPreferredSize(getDisplayAreaDimension());
		return canvas;
	}

	private Dimension getDisplayAreaDimension() {
		return new Dimension(displayWidth, displayHeight);
	}

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
					g2d.drawString("Parabéns! Você acertou a palavra secreta", 20, size.height-20);
				}else{  //Jogador perdeu
					g2d.setColor(Color.red);
					g2d.drawString("Fim de jogo! A palavra era: " + secretWord, 20, size.height-20);
				}
			}
		}
	}

}