package mars.tools;

import java.awt.Color;
import java.awt.Container;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.GraphicsConfiguration;
import java.awt.Image;
import java.util.Observable;

import javax.swing.ImageIcon;
import javax.swing.JComponent;
import javax.swing.JLabel;
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
	private static String version = " Version 1.0";
	private static int displayWidth = 650;
	private static int displayHeight = 350;

	public static final int CARREGANDO_PALAVRA = 1;
	public static final int JOGO_EM_EXECUCAO = 2;
	public static final int FIM_DE_JOGO = 3;

	protected Graphics g;
	private JPanel canvas;
	protected int lastAddress = -1;
	protected JLabel label;
	private Container painel = this.getContentPane();
	private GraphicsConfiguration gc;

	private int baseAddress;
	private String statusAddress;
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
		super(heading + ", " + version, heading);
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
		new JogoDaForca(heading + ", " + version, heading).go();
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
			// if (Character.isValidCodePoint(value))
			// 	System.out.println("write: " + address + " : " + Character.toString(value));
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
				String currentAddress = Integer.toHexString(baseAddress);
				String end16MSB = currentAddress.substring(0, 4);
				if (end.substring(0, 4).equals(end16MSB)){
					updateGame(info);
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
		int offset = address - baseAddress;
		//Substituir letra na posição
		char[] arr = secretMask.toCharArray();
		arr[offset] = secretWord.charAt(offset);
		secretMask = new String(arr);
		//System.out.println(secretMask);
	}

	protected void updateDisplay() {
		canvas.repaint();
	}

	// public void paint(Graphics g) {
	// 	super.paint(g);
	// 	Graphics2D g2 = (Graphics2D) g;
	// 	Dimension size = getSize();
	// 	FontRenderContext frc = g2.getFontRenderContext();
	// 	Font font = new Font("Verdana", Font.PLAIN, 20);
	// 	g.setFont(font);
	// 	g.setColor(Color.blue);
	// 	g.drawString(secretMask, size.width / 2, size.height / 2);
	// }

	protected void initializePostGUI() {
		updateDefaultAddress();
	}

	protected void reset() {
		secretMask = "";
		secretWord = "";
		//resetar o background
		updateDisplay();
	}

	private void updateDefaultAddress() {
		baseAddress = Memory.dataSegmentBaseAddress;
		statusAddress = "10010500";
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
			//BG
			paintBackground(g);
			//Texto
			if (secretMask != null)
				paintText(g);
		}

		private void paintBackground(Graphics g){
			System.setProperty("sun.java2d.translaccel", "true");
			ImageIcon icon = new ImageIcon(getClass().getResource(Globals.imagesPath + "Forca.jpg"));
			Image im = icon.getImage();
			Dimension size = getSize();
			g.drawImage(im, 0, 0, size.width, size.height, null);
		}

		private void paintText(Graphics g){
			Dimension size = getSize();
			Font font = new Font("Verdana", Font.BOLD, 24);
			g.setFont(font);
			g.setColor(Color.blue);
			String word = "";
			for (int i=0; i<secretMask.length(); i++){
				word += secretMask.charAt(i);
				if (i != secretMask.length()-1){
					word += " ";
				}
			}
			g.drawString(word, (size.width/2)-70, size.height/2);
		}
	}

}