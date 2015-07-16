# Phosfosol
Abort Factor é um ataque publicado na Black Hat de 2012 por dois pesquisadores japoneses. 
Esse ataque consiste em alterar apenas um byte de algumas estruturas do Kernel do Windows de forma a anular 
o funcionamento de diversas ferramentas (senão todas) voltadas para análise de dumps de memória.  

O Phosfosol é um projeto do OctaneLabs, criado por Tony Rodrigues e Diego Fuschini, cujo objetivo é resgatar 
alguns dados (DTB do Kernel e Profile do dump) a fim de retomar a capacidade de análise de dumps de memória 
a ferramentas como o Volatility.
