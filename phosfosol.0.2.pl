
# Anti-Anti-Forense de Memoria
# OctaneLabs - Tony Rodrigues - dartagnham at gmail dot com
# uso: phosfosol.pl -f arquivo [-h] [-l language] [-c]
# 
# -f :arquivo dump de memoria
# -l :language (En, PtBr)
# -c :check memory dump
# -h :mensagem de ajuda
#
# 
#
#pendencias:
# - tempo de execução
# - optimização dos algoritmos
# - colocar o size para os profiles q estão faltando
# - implementar -c para cada tipo de ataque


use Getopt::Std;

my $ver="0.2";

#16
my %lhTrans = (En   => {
                        "usage" => "usage",
                        "file" => "file",
                        "language" => "language",
                        "memory dump file" => "memory dump file",
                        "language (En, PtBr)" => "language (En, PtBr)",
                        "this help" => "this help",
                        "Enter -f memory_dump_file. Ex: phosfosol.pl -f c:\\dir\\dump_memo.raw \n" => "Enter -f memory_dump_file. Ex: phosfosol.pl -f c:\\dir\\dump_memo.raw \n",
                        "Reading offset ... " => "Reading offset ... ",
                        "\nCandidate DTB and Profile:\n" => "\nCandidate DTB and Profile:\n",
                        "-> KDBG Confirmed\n" => "-> KDBG Confirmed\n",
                        "%d bits Operational System (via KDGB)\n" => "%d bits Operational System (via KDGB)\n", 
                        "32 bits PAE Operational System (self-ref pages)\n" => "32 bits PAE Operational System (self-ref pages)\n", 
                        "32 bits Non-PAE Operational System (self-ref pages)\n" => "32 bits Non-PAE Operational System (self-ref pages)\n", 
                        "64 bits Operational System (self-ref pages)\n" => "64 bits Operational System (self-ref pages)\n",
                        "No DTB/Profile information found\n" => "No DTB/Profile information found\n",
                        "Memory Anti-Anti-Forensics - Aborting the Abort Factor" => "Memory Anti-Anti-Forensics - Aborting the Abort Factor",
                        "check memory dump" => "check memory dump",
                        "Could not find Idle Process\n" => "Could not find Idle Process\n",
                        "Idle Process Dispatch Header Abort Factor Confirmed\n" => "Idle Process Dispatch Header Abort Factor Confirmed\n"
                       },
               PtBr => {
                        "usage" => "uso",
                        "file" => "arquivo",
                        "language" => "idioma",
                        "memory dump file" => "arquivo dump de memoria",
                        "language (En, PtBr)" => "idioma (En, PtBr)",
                        "this help" => "mensagem de ajuda",
                        "Enter -f memory_dump_file. Ex: phosfosol.pl -f c:\\dir\\dump_memo.raw \n" => "Entre com -f nome_do_arquivo_de_dump_de_memoria. Ex: phosfosol.pl -f c:\\dir\\dump_memo.raw \n",
                        "Reading offset ... " => "Pesquisando offset ... ",
                        "\nCandidate DTB and Profile:\n" => "\nPossivel DTB e Profile:\n",
                        "-> KDBG Confirmed\n" => "-> Confirmado pelo KDBG\n",
                        "%d bits Operational System (via KDGB)\n" => "Sistema Operacional de %d bits (via KDGB)\n", 
                        "32 bits PAE Operational System (self-ref pages)\n" => "Sistema Operacional de 32 bits com PAE (self-ref pages)\n", 
                        "32 bits Non-PAE Operational System (self-ref pages)\n" => "Sistema Operacional de 32 bits Non-PAE (self-ref pages)\n", 
                        "64 bits Operational System (self-ref pages)\n" => "Sistema Operacional de 64 bits (self-ref pages)\n",
                        "No DTB/Profile information found\n" => "Nenhuma informação relevante foi localizada\n",
                        "Memory Anti-Anti-Forensics - Aborting the Abort Factor" => "Anti-Anti-Forense de Memoria - Aborting the Abort Factor",
                        "check memory dump" => "Verifica Abort Factor no dump de memoria",
                        "Could not find Idle Process\n" => "Processo Idle nao foi localizado\n",
                        "Idle Process Dispatch Header Abort Factor Confirmed\n" => "Abort Factor do Dispatch Header do Processo Idle Confirmado\n"
                       }
               );

#opcoes
%args = ( );
getopts("f:l:hc", \%args);

#Default = English
$args{l} = "En" unless ($args{l});
$args{l} = "En" unless (($args{l} eq "En") || ($args{l} eq "PtBr"));

my $lsLang = $args{l};

#coloca mensagem explicativa
if ($args{h}) {
   &cabecalho;
   print <<DETALHE;
$lhTrans{$lsLang}->{"usage"}: phosfosol.pl -f $lhTrans{$lsLang}->{"file"} [-h] [-l $lhTrans{$lsLang}->{"language"}]
 
 -f :$lhTrans{$lsLang}->{"memory dump file"}
 -l :$lhTrans{$lsLang}->{"language (En, PtBr)"}
 -c :$lhTrans{$lsLang}->{"check memory dump"}
 -h :$lhTrans{$lsLang}->{"this help"}
 
  Ex: phosfosol.pl -f c:\\diretorio\\dump_memo.raw 

DETALHE
   exit;
}

die $lhTrans{$lsLang}->{"Enter -f memory_dump_file. Ex: phosfosol.pl -f c:\\dir\\dump_memo.raw \n"} unless ($args{f});

#Inicializa hash com: distancia do imagename para o dtb, do dtb para o eprocess, size do KDBG , Size do Dispatcher_Header.
%lhProfiles = ( WinXPSP3x86 => [-348,-24, 656, 0x1B],
            WinXPSP2x86 => [-348,-24, 656, 0x1B],
            VistaSP0x86 => [-308,-24, 808, 0x20],
            VistaSP0x64 => [-528,-40, 808, 0x30],
            VistaSP1x86 => [-308,-24, 816, 0x20],
            VistaSP1x64 => [-528,-40, 808, 0x30],
            VistaSP2x86 => [-308,-24, 816, 0x20],
            VistaSP2x64 => [-528,-40, 808, 0x30],
            Win2008SP1x64 => [-528,-40, 816, 0x30],
            Win2008SP2x64 => [-528,-40, 816, 0x30],
            Win2008SP1x86 => [-308,-24, 816, 0x20],
            Win2008SP2x86 => [-308,-24, 816, 0x20],
            Win7SP0x86 => [-340,-24, 656, 0x26],
            Win7SP1x86 => [-340,-24, 656, 0x26],
            Win7SP0x64 => [-696,-40, 832, 0x58],
            Win7SP1x64 => [-696,-40, 832, 0x58],
            Win2008R2SP0x64 => [-696,-40, 832, 0x58],
            Win2008R2SP1x64 => [-696,-40, 832, 0x58],
            Win2003SP0x86 => [-316,-24, 816, 0x1E],
            Win2003SP1x86 => [-332,-24, 816, 0x1E],
            Win2003SP2x86 => [-332,-24, 816, 0x1E],
            Win2003SP1x64 => [-576,-40, 792, 0x2E],
            Win2003SP2x64 => [-576,-40, 792, 0x2E],
            WinXPSP1x64 => [-576,-40, 656, 0x2E],
            WinXPSP2x64 => [-576,-40, 656, 0x2E],
           );

#WINXPSP1 -> ImageFileName: 0x174; DTB: 0x18;
#WINXPSP2 -> ImageFileName: 0x174; DTB: 0x18;
#WINXPSP3 -> ImageFileName: 0x174; DTB: 0x18;
#VISTASP0x64 -> ImageFileName: 0x238; DTB: 0x28;
#VISTASP0x32 -> ImageFileName: 0x14c; DTB: 0x18;
#VISTASP1x64 -> ImageFileName: 0x238; DTB: 0x28;
#VISTASP1x32 -> ImageFileName: 0x14c; DTB: 0x18;
#VISTASP2x64 -> ImageFileName: 0x238; DTB: 0x28;
#VISTASP2x32 -> ImageFileName: 0x14c; DTB: 0x18;
#Win7SP0x86 -> ImageFileName: 0x16c; DTB: 0x18;
#Win7SP1x86 -> ImageFileName: 0x16c; DTB: 0x18;
#Win7SP0x64 -> ImageFileName: 0x2e0; DTB: 0x28;
#Win7SP1x64 -> ImageFileName: 0x2e0; DTB: 0x28;
#Win2008R2SP0x64 -> ImageFileName: 0x2e0; DTB: 0x28;
#Win2008R2SP1x64 -> ImageFileName: 0x2e0; DTB: 0x28;
#Win2003SP0x86 -> ImageFileName: 0x154; DTB: 0x18;
#Win2003SP1x86 -> ImageFileName: 0x164; DTB: 0x18;
#Win2003SP2x86 -> ImageFileName: 0x164; DTB: 0x18;
#Win2003SP1x64 -> ImageFileName: 0x268; DTB: 0x28;
#Win2003SP2x64 -> ImageFileName: 0x268; DTB: 0x28;
#WinXPSP1x64 -> ImageFileName: 0x268; DTB: 0x28;
#WinXPSP2x64 -> ImageFileName: 0x268; DTB: 0x28;

#para o progress        
local $| = 1;

#arquivo dump
my $lsDumpName = $args{f};

#tamanho do dump
my $lnDumpSize = -s $lsDumpName;

#Abre o arquivo de memória, modo bin
open(MEMO, "< :raw", $lsDumpName); 

#printf "%#x\n", &enderecofisico(0x337000, 0x804d7000, 0, 1, MEMO, $lnDumpSize);
   
#exit;
#----------------
my $lnPageBytes="";
my $__PAGESIZE = 4*1024*1024;  #4Mb
my $lnRead;
my $lnOffset=0;
my %lhDTBCandidateIdle = ();
my %lhDTBCandidatePage = ();
my %lhKDBG = ();
my $lbStopReading = 0;

my $lsProgMsg = $lhTrans{$lsLang}->[7];

print $lsProgMsg;

#Percorre o arquivo por páginas grandes
until ($lbStopReading) {
   
   #progresso
   print "\b" x length($lsProgMsg);
   $lsProgMsg = $lhTrans{$lsLang}->{"Reading offset ... "}. " $lnOffset";
   print $lsProgMsg;
   
   #posiciona
   seek(MEMO, $lnOffset, 0);
   
   #le uma pagina 
   $lnRead = read(MEMO, $lnPageBytes, $__PAGESIZE);
   $lbStopReading = eof(MEMO);
      
   my $lnPos;
   my $lnValDTB;
      
   #procura pelo lhKDBG
   while ($lnPageBytes =~ /(\x00\x00\x00\x00\x00\x00\x00\x00|\x00\xf8\xff\xff)(KDBG)(.{2})/g) {
      my $lsArchPat = $1;
      my $lnKDBGSize = unpack("S", $3);
      $lnPos=$-[2];
      
      #guarda apenas o primeiro de cada size encontrado. Guarda se é 32 ou 64bit e o offset do inicio da estrutura
      $lhKDBG{$lnKDBGSize}=[($lsArchPat=~/\x00{8}/?32:64),($lnPos+$lnOffset-16)] unless (exists($lhKDBG{$lnKDBGSize}));
      #printf "$lnKDBGSize $lhKDBG{$lnKDBGSize}->[0] %#x\n", $lhKDBG{$lnKDBGSize}->[1];     
   }
          
   #procura pelo nome do processo Idle, buscando candidatos a DTB
   while ($lnPageBytes =~ /Idle\x00{10}/g) {
      
      #suposta posição do ImageFileName 
      $lnPos=$-[0];
            
      my $lsProfile;
      foreach $lsProfile (keys %lhProfiles) {
         #captura o suposto Dispatch_Header         
         my $lsDispHeader = substr($lnPageBytes, $lnPos+$lhProfiles{$lsProfile}->[0]+$lhProfiles{$lsProfile}->[1],8);
         
         #compara com o esperado. Ajuda a filtrar os falso-positivos. Não considera o Size por causa do Abort Factor
         if ($lsDispHeader =~ /\x03\x00(.{1})\x00/) {
            $lnValDTB = quad(substr($lnPageBytes, $lnPos+$lhProfiles{$lsProfile}->[0],8));
            
            #DTBs são alinhados em 0x20
            if (($lnValDTB % 0x20) == 0) { 
               my $lnEndEProc = $lnPos+$lhProfiles{$lsProfile}->[0]+$lhProfiles{$lsProfile}->[1]+$lnOffset;
               $lhDTBCandidateIdle{$lnValDTB}{$lsProfile}=$lnEndEProc unless exists($lhDTBCandidateIdle{$lnValDTB});
               #printf "DTB pos->%#x %#x\n", ($lnPos+$lhProfiles{$lsProfile}->[0]+$lnOffset), $lnValDTB;
            }
         }         
      }
   }
   
   #Busca páginas pelo auto-referenciamento
   $lnPos = 0;
   my $j;
   
   for ($j=0; $j < ($__PAGESIZE/32);$j++) {      
      $lnPos = 32*$j;
      $lnValDTB = $lnOffset+$lnPos;
      
      #só avança se for alinhado em 0x20
      next unless (($lnValDTB % 0x20) == 0);
      
      if (($lnValDTB % 0x1000) == 0) {
         #32bit sem PAE
         my $a = unpack("L",substr($lnPageBytes,$lnPos+0xC00, 4));
         
         if ((($a & 0xFFFFF000) == $lnValDTB) && (($a & 0x1) == 0x1)) {
            $lhDTBCandidatePage{$lnValDTB}=1;
         }
         
         #64bits
         $a = unpack("L",substr($lnPageBytes,$lnPos+0xf68, 4));
         my $b = unpack("L",substr($lnPageBytes,$lnPos+0xf6c, 4));
         
         if ((($a & 0xFFFFF000) == $lnValDTB) && (($b & 0x7FFFF000) == 0) && (($a & 1) == 1) ) {
            $lhDTBCandidatePage{$lnValDTB}=2;
         }
      }
      
      my $x = unpack("L",substr($lnPageBytes,$lnPos, 4)) & 0xFFFFF000;      
      next if ($x==0);
   
      my $y = unpack("L",substr($lnPageBytes,$lnPos+8, 4)) & 0xFFFFF000;
      next if (($y==0) or ($x==$y));
   
      my $z = unpack("L",substr($lnPageBytes,$lnPos+16, 4)) & 0xFFFFF000;
      next if (($z==0) or ($z==$y) or ($z==$x));
   
      my $w = unpack("L",substr($lnPageBytes,$lnPos+24, 4)) & 0xFFFFF000;      
      next if (($w==0) or ($w==$y) or ($w==$x) or ($w==$z));
   
      next if ($w == $lnValDTB);
   
      #if (($w>=$lnOffset) && ($w <= ($lnOffset+$lnRead-1))) {
      #   $buf = substr($lnPageBytes,$w-$lnOffset,32);
      #}
      #else {
         seek(MEMO, $w, 0);
         my $buf = "";
         read(MEMO, $buf, 32);
      #}
   
      next if ($x != (unpack("L",substr($buf,0,4)) & 0xFFFFF000));
            
      next if ($y != (unpack("L",substr($buf,8,4)) & 0xFFFFF000));
      
      next if ($z != (unpack("L",substr($buf,16,4)) & 0xFFFFF000));
      
      next if ($w != (unpack("L",substr($buf,24,4)) & 0xFFFFF000));
   
      #achamos uma página que pode ser um directory table
      #só coloca como candidato se ele está alinhado em 0x20
      $lhDTBCandidatePage{$lnValDTB}=0;
   
      
      
      #printf "DTB Pagina %#x\n", ($lnOffset+$lnPos);
      #printf "x=%#x y=%#x z=%#x w=%#x\n", $x, $y, $z, $w if (($lnOffset+$lnPos)==181927968);
      
   }
   
   #le a proxima pagina
   $lnOffset += $lnRead;
   
}



my $lbOk=0;
my $lnFoundDTB;
my $lsFoundProfile;
my $lnFoundKDBG;
my $lnArchKDBG;

#Busca quem é igual
foreach my $lnThisDTB (keys %lhDTBCandidateIdle) {
   if (exists($lhDTBCandidatePage{$lnThisDTB})) {
      $lbOk=1;
      
      foreach $lsProfile (keys $lhDTBCandidateIdle{$lnThisDTB}) {
         $lnFoundDTB = $lnThisDTB;
         $lsFoundProfile = $lsProfile;
         
         if (exists($lhKDBG{$lhProfiles{$lsProfile}->[2]})) {
            $lnFoundKDBG = $lhKDBG{$lhProfiles{$lsProfile}->[2]}->[1];
            $lnArchKDBG  = $lhKDBG{$lhProfiles{$lsProfile}->[2]}->[0];
         }
         else {
            $lnFoundKDBG = 0;
            $lnArchKDBG  = 0;
         }         
      }
   }
}

#imprime resultados
if ($lbOk) {
   print $lhTrans{$lsLang}->{"\nCandidate DTB and Profile:\n"};
   print "--------------------------\n";
   printf "       DTB=%#x\n", $lnFoundDTB;
   print  "   PROFILE=$lsFoundProfile " . (exists($lhKDBG{$lhProfiles{$lsFoundProfile}->[2]}) ? $lhTrans{$lsLang}->{"-> KDBG Confirmed\n"}: "\n");
   
   if ($lnFoundKDBG != 0) {
      printf "      KDBG=%#x\n", $lnFoundKDBG;
      printf $lhTrans{$lsLang}->{"%d bits Operational System (via KDGB)\n"}, $lnArchKDBG;
   }
   
   print $lhTrans{$lsLang}->{"32 bits PAE Operational System (self-ref pages)\n"} if ($lhDTBCandidatePage{$lnFoundDTB}==0);
   print $lhTrans{$lsLang}->{"32 bits Non-PAE Operational System (self-ref pages)\n"} if ($lhDTBCandidatePage{$lnFoundDTB}==1);
   print $lhTrans{$lsLang}->{"64 bits Operational System (self-ref pages)\n"} if ($lhDTBCandidatePage{$lnFoundDTB}==2);
}
else {
   print $lhTrans{$lsLang}->{"No DTB/Profile information found\n"};
   
   #Faz uma verificacao mais detalhada porque não houve correlacao (Eprocess do Idle pode nao ter sido encontrado)
   
}

if ($args{c}) {
   #pediu -c
   
   #verifica abort factor do Dispatch Header
   my $lnEProcIdle = defined($lhDTBCandidateIdle{$lnFoundDTB}{$lsFoundProfile})? $lhDTBCandidateIdle{$lnFoundDTB}{$lsFoundProfile}:0;
   if ($lnEProcIdle==0) {
      print $lhTrans{$lsLang}->{"Could not find Idle Process\n"};
   }
   else {
      &checkDispatchHeader($lnFoundDTB, $lnEProcIdle, MEMO, $lsFoundProfile);
   }
   
   #verifica PoolTag
   
   #verifica version do executavel do kernel
   
}

close(MEMO);

#---Fim do programa principal

sub checkDispatchHeader {
   my $pDTB = shift;
   my $pEprocIdle = shift;
   my $pARQ = shift;
   my $pProf = shift;
   
   #Busca o size do Dispath Header
   Seek($pARQ, $pEprocIdle+2, 0);
   my $buf = "";
   read($pARQ, $buf, 1);
   
   my $lnThisSize = unpack("C", $buf);
   
   if ($lnThisSize != $lhProfiles{$pProf}->[3]) {
      print "Idle Process Dispatch Header Abort Factor Confirmed\n";
   }
   
}

sub enderecofisico {
   my $pDTB = shift;
   my $pEndVir = shift;
   my $px64 = shift;
   my $pPAE = shift;
   my $pARQ = shift;
   my $pSize = shift;
   
   my $lnSaida = 0;
   
   if ($px64) {
      #se eh x64
      my $lnPDM = 0;
      my $lnPDP = 0;
      my $lnPDI = 0;
      my $lnPTI = 0;
      my $lnBI = 0;
            
      $lnPDM = (($pEndVir >> 39) & 0x1FF) << 3;      
      $lnPDP = (($pEndVir >> 30) & 0x1FF) << 3;
      $lnPDI = (($pEndVir >> 21) & 0x1FF) << 3;
      $lnPTI = (($pEndVir >> 12) & 0x1FF) << 3;
      $lnBI  = ($pEndVir & 0xFFF);
      
      seek($pARQ,$pDTB+$lnPDM, 0);
      my $buf = "";
      read($pARQ, $buf, 8);
         
      my $lnAuxLow = (unpack("L",substr($buf,0,4)) & 0xFFFFF000);
      my $lnAuxHi = (unpack("L",substr($buf,4,4)) & 0x0000FFFF);
      
      seek($pARQ,($lnAuxHi << 32) + $lnAuxLow + $lnPDP , 0);
      $buf = "";
      read($pARQ, $buf, 8);
      
      $lnAuxLow = (unpack("L",substr($buf,0,4)) & 0xFFFFF000);
      $lnAuxHi = (unpack("L",substr($buf,4,4)) & 0x0000FFFF);
      
      seek($pARQ,($lnAuxHi << 32) + $lnAuxLow + $lnPDI , 0);
      $buf = "";
      read($pARQ, $buf, 8);
      
      my $lnPDELow = (unpack("L",substr($buf,0,4)));
      my $lnPDEHi = (unpack("L",substr($buf,4,4)) & 0x0000FFFF);
      
      my $lbLarge = ($lnPDELow >> 7) & 0x1;      
      my $lbPresent = $lnPDELow & 0x1;
      
      return 0 if ($lbPresent == 0);
      
      $lnPDELow = ($lnPDELow & 0xFFFFF000);
      
      if ($lbLarge) {
         if ($pPAE) {
            $lnBI += ($lnPTI << 9);
             
            $lnPDELow = $lnPDELow & 0xFFE00000;
            $lnSaida = ($lnPDEHi << 32) + $lnPDELow + $lnBI;
         }
         else {
            $lnBI += ($lnPTI << 10);
         
            $lnSaida = ($lnPDEHi << 32) + $lnPDELow + $lnBI;
         }
      }
      else {
         if ($pPAE) {
            seek($pARQ,($lnPDEHi << 32) + $lnPDELow + $lnPTI , 0);
            $buf = "";
            read($pARQ, $buf, 8);
            
            my $lnPTAuxLow = (unpack("L",substr($buf,0,4)) & 0xFFFFF000);
            my $lnPTAuxHi = (unpack("L",substr($buf,4,4)) & 0x0000FFFF);
         
            $lnSaida = ($lnPTAuxHi << 32) + $lnPTAuxLow + $lnBI;
         }
         else {
            seek($pARQ,($lnPDEHi << 32) + $lnPDELow + $lnPTI , 0);
            $buf = "";
            read($pARQ, $buf, 4);
         
            my $lnPage = (unpack("L",substr($buf,0,4)) & 0xFFFFF000);
         
            $lnSaida = $lnPage + $lnBI;
         }
      }            
   }
   elsif ($pPAE) {
      #32bit PAE
      my $lnPDP = 0;
      my $lnPDI = 0;
      my $lnPTI = 0;
      my $lnBI = 0;
            
      $lnPDP = ($pEndVir >> 30) << 3;
      $lnPDI = (($pEndVir >> 21) & 0x1FF) << 3;
      $lnPTI = (($pEndVir >> 12) & 0x1FF) << 3;
      $lnBI  = ($pEndVir & 0xFFF);
            
      #capturamos o Page Table Entry
      seek($pARQ,$pDTB+$lnPDP, 0);
      my $buf = "";
      read($pARQ, $buf, 8);
         
      my $lnPDEAuxLow = (unpack("L",substr($buf,0,4)) & 0xFFFFF000);
      my $lnPDEAuxHi = (unpack("L",substr($buf,4,4)) & 0x0000FFFF);
      
      seek($pARQ,($lnPDEAuxHi << 32) + $lnPDEAuxLow + $lnPDI , 0);
      $buf = "";
      read($pARQ, $buf, 8);
      
      my $lnPDELow = (unpack("L",substr($buf,0,4)));
      my $lnPDEHi = (unpack("L",substr($buf,4,4)) & 0x0000FFFF);
      
      my $lbLarge = ($lnPDELow >> 7) & 0x1;      
      my $lbPresent = $lnPDELow & 0x1;
      
      return 0 if ($lbPresent == 0);
      
      $lnPDELow = ($lnPDELow & 0xFFFFF000);
      
      if ($lbLarge) {
         #PS setado == 4Mb pages
         $lnBI += ($lnPTI << 9);
         
         $lnPDELow = $lnPDELow & 0xFFE00000;
         $lnSaida = ($lnPDEHi << 32) + $lnPDELow + $lnBI;
         
      }
      else {
         seek($pARQ,($lnPDEHi << 32) + $lnPDELow + $lnPTI , 0);
         $buf = "";
         read($pARQ, $buf, 8);
         
         my $lnPTAuxLow = (unpack("L",substr($buf,0,4)) & 0xFFFFF000);
         my $lnPTAuxHi = (unpack("L",substr($buf,4,4)) & 0x0000FFFF);
         
         $lnSaida = ($lnPTAuxHi << 32) + $lnPTAuxLow + $lnBI;
                  
      }
   }
   else {
      #32bit nonPAE
      my $lnPDP = 0;
      my $lnPDI = 0;
      my $lnPTI = 0;
      my $lnBI = 0;
            
      
      $lnPDI = (($pEndVir >> 22) & 0x1FF) << 2;
      $lnPTI = (($pEndVir >> 12) & 0x3FF) << 2;
      $lnBI  = ($pEndVir & 0xFFF);
      
      #capturamos o Page Table Entry
      seek($pARQ,$pDTB+$lnPDI, 0);
      my $buf = "";
      read($pARQ, $buf, 4);
         
      my $lnPTE = unpack("L",substr($buf,0,4));
      
      my $lbLarge = ($lnPTE >> 7) & 0x1;      
      my $lbPresent = $lnPTE & 0x1;
      
      return 0 if ($lbPresent == 0);
      
      $lnPTE = ($lnPTE & 0xFFFFF000);
      
      if ($lbLarge) {
         $lnBI += ($lnPTI << 10);
         
         $lnSaida = $lnPTE + $lnBI;
      }
      else {
         seek($pARQ,$lnPTE + $lnPTI , 0);
         $buf = "";
         read($pARQ, $buf, 4);
         
         my $lnPage = (unpack("L",substr($buf,0,4)) & 0xFFFFF000);
         
         $lnSaida = $lnPage + $lnBI;
         
      }
   }
   
   #retorna 0 se for maior que o tamanho do arquivo
   return ($lnSaida >= $pSize)? 0: $lnSaida;
   
}

sub quad {
    my( $str )= @_;
    my $big;
    
    $little = unpack("C", pack("S", 1));
    
    if(!eval {$big= unpack("Q", $str); 1;}) {
      my ( $lo, $hi )= unpack("LL", $str);
      
      ($hi, $lo) = ($lo, $hi)   if  !$little;
      
      $big= $lo + $hi*( 1 + ~0 );      
    }
    return $big;
}

sub cabecalho {
   print <<CABEC;

phosfosol.pl v$ver
$lhTrans{$lsLang}->{"Memory Anti-Anti-Forensics - Aborting the Abort Factor"}
Tony Rodrigues - OctaneLabs
dartagnham at gmail dot com
--------------------------------------------------------------------------

CABEC
}

#-----EOF-------
