module UART(
    input wire[23:0] baud,       // Paramètre de baud rate
    input wire clk_xtal,         // Signal d'horloge
    input wire send,             // Signal pour démarrer la transmission
    input wire[7:0] DataOut,     // Données à transmettre
    input wire rx,               // Ligne de réception
    input wire read,             // Signal de lecture du FIFO
    input wire rst,              // Signal de reset
    output reg tx,               // Ligne de transmission
    output reg[7:0] DataIn,      // Données reçues
    output wire busy,            // Indicateur de transmission en cours
    output wire fifo_empty,     ²      // Indicateur FIFO vide
    output wire fifo_full        // Indicateur FIFO plein
);
    // Déclaration des registres pour le générateur de baud
    reg[23:0] cnt;               // Compteur pour le diviseur de baud
    reg clk_baud;                // Horloge correspondant au baud rate
    reg clk_baud_prev;           // Pour détecter les fronts de clk_baud
    wire clk_baud_edge;          // Front montant de clk_baud
    
    // États de transmission et réception
    reg transmitting, latch;     // État de transmission
    reg receiving;               // État de réception
    reg[9:0] tx_shift_reg;       // Registre à décalage pour TX
    reg[9:0] rx_shift_reg;       // Registre à décalage pour RX
    reg[3:0] tx_bit_count;       // Compteur de bits transmis
    reg[3:0] rx_bit_count;       // Compteur de bits reçus
    reg rx_d1, rx_d2;            // Pour détecter le front descendant de rx
    
    // FIFO de réception
    reg [7:0] FIFOin [0:7];      // FIFO de 8 éléments
    reg [2:0] Rpointer, Wpointer; // Pointeurs de lecture et écriture
    reg [3:0] fifo_count;        // Compteur d'éléments dans le FIFO
    
    // Signaux de contrôle du FIFO
    assign busy = transmitting;
    assign fifo_empty = (fifo_count == 4'b0);
    assign fifo_full = (fifo_count == 4'd8);
    
    // Variables pour la synchronisation de lecture
    reg read_d1, read_d2;
    wire read_edge;
    
    // Détection des fronts
    assign clk_baud_edge = clk_baud && !clk_baud_prev;
    assign read_edge = read && !read_d1;
    
    // Initialisation
    initial begin
        cnt = 24'b0;
        clk_baud = 1'b0;
        clk_baud_prev = 1'b0;
        transmitting = 1'b0;
        latch = 1'b1;
        receiving = 1'b0;
        tx = 1'b1;               // Ligne idle en état haut
        tx_bit_count = 4'b0;
        rx_bit_count = 4'b0;
        Rpointer = 3'b0;
        Wpointer = 3'b0;
        fifo_count = 4'b0;
        DataIn = 8'b0;
        read_d1 = 1'b0;
        read_d2 = 1'b0;
        
        // Initialiser le FIFO
        FIFOin[0] = 8'b0;
        FIFOin[1] = 8'b0;
        FIFOin[2] = 8'b0;
        FIFOin[3] = 8'b0;
        FIFOin[4] = 8'b0;
        FIFOin[5] = 8'b0;
        FIFOin[6] = 8'b0;
        FIFOin[7] = 8'b0;
    end
    
    // Tout synchronisé sur clk_xtal
    always @(posedge clk_xtal) begin
        if (rst) begin
            // Reset du générateur de baud
            cnt <= 24'b0;
            clk_baud <= 1'b0;
            clk_baud_prev <= 1'b0;
            
            // Reset de la transmission
            transmitting <= 1'b0;
            latch <= 1'b1;
            tx <= 1'b1;
            tx_bit_count <= 4'b0;
            
            // Reset de la réception
            receiving <= 1'b0;
            rx_bit_count <= 4'b0;
            rx_d1 <= 1'b1;
            rx_d2 <= 1'b1;
            
            // Reset du FIFO
            Rpointer <= 3'b0;
            Wpointer <= 3'b0;
            fifo_count <= 4'b0;
            DataIn <= 8'b0;
            read_d1 <= 1'b0;
            read_d2 <= 1'b0;
        end else begin
            // ========== GÉNÉRATEUR DE BAUD RATE ==========
            clk_baud_prev <= clk_baud;
            if(cnt >= (24'd13499999/baud)) begin
                cnt <= 24'b0;
                clk_baud <= ~clk_baud;
            end else begin
                cnt <= cnt + 24'b1;
            end
            
            // ========== SYNCHRONISATION DES SIGNAUX ==========
            rx_d1 <= rx;
            rx_d2 <= rx_d1;
            read_d1 <= read;
            read_d2 <= read_d1;
            
            // ========== LOGIQUE DE TRANSMISSION ==========
            if (clk_baud_edge) begin
                // Démarrer une nouvelle transmission
                latch <= send ? latch : 1'b1;
                if(send && !transmitting && latch) begin
                    transmitting <= 1'b1;
                    latch <= 1'b0;
                    tx_shift_reg <= {1'b1, DataOut, 1'b0}; // {stop bit, data, start bit}
                    tx_bit_count <= 4'b0;
                end
                // Continuer la transmission
                else if(transmitting) begin
                    if(tx_bit_count < 4'd9) begin
                        tx_bit_count <= tx_bit_count + 4'b1;
                        tx <= tx_shift_reg[tx_bit_count];
                    end else begin
                        transmitting <= 1'b0;
                        tx <= 1'b1; // Retour à l'état idle
                    end
                end
                
                // ========== LOGIQUE DE RÉCEPTION ==========
                // Détecter un bit de start
                if(!receiving && rx_d2 == 1'b1 && rx_d1 == 1'b0) begin
                    receiving <= 1'b1;
                    rx_bit_count <= 4'b0;
                    rx_shift_reg <= 10'b0;
                end
                // Continuer la réception
                else if(receiving) begin
                    if(rx_bit_count < 4'd9) begin
                        rx_shift_reg[rx_bit_count] <= rx;
                        rx_bit_count <= rx_bit_count + 4'b1;
                    end
                    // Fin de la réception
                    else begin
                        // Vérifier que le bit de stop est 1 et que le FIFO n'est pas plein
                        if(rx == 1'b1 && !fifo_full) begin
                            FIFOin[Wpointer] <= rx_shift_reg[8:1]; // Extraire les 8 bits de données
                            Wpointer <= Wpointer + 3'b1;
                            fifo_count <= fifo_count + 4'b1;
                        end
                        receiving <= 1'b0;
                    end
                end
            end
            
            // ========== LOGIQUE DE LECTURE DU FIFO ==========
            if(read_edge && !fifo_empty) begin
                DataIn <= FIFOin[Rpointer];
                Rpointer <= Rpointer + 3'b1;
                fifo_count <= fifo_count - 4'b1;
            end
        end
    end
    
endmodule