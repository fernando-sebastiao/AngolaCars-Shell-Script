#!/bin/bash

source ./menu_carro.sh
source ./menu_usuarios.sh
source ./menu_filial.sh
source ./menu_vendas.sh
source ./menu_recepcao.sh

menu_admin() {
  while true; do
    clear
    echo "===== MENU ADMIN - ANGOLA CARS ====="
    echo "[1] Gerir carros"
    echo "[2] Gerir funcionarios(usuarios)"
    echo "[3] Gerir filial"
    echo "[4] Menu venda"
    echo "[5] Ver relatório"
    echo "[0] Sair"
    read -p "Opção: " op
    case $op in
      1) menu_carro;;
      2) menu_usuarios;;
      3) menu_filial;;
      4) menu_vendas;;
      5) echo "→ Ver relatório (a implementar)";;
      0) break;;
      *) echo "Opção inválida";;
    esac
    read -p "ENTER para continuar..."
  done
 }

menu_admin_filial() {
  local nome_filial="$1"

  while true; do
    clear
    echo "===== MENU ADMIN - ANGOLA CARS - FILIAL $nome_filial ====="
    echo "[1] Gerir carro"
    echo "[2] Listar carros disponiveis antes de vender"
    echo "[3] Registrar venda"
    echo "[4] Listar Vendas - Geral"
    echo "[5] Pesquisar Venda"
    echo "[6] Emitir comprovativo de Venda"
    echo "[7] Listar Relatorio de Venda da Filial"
    echo "[0] Sair"
    read -p "Opção: " op
    case $op in
      1) menu_carro;;
      2) listar_carros;;
      3) criar_venda;;
      4) abrir_vendas;;
      5) pesquisar_venda;;
      6) emitir_comprovativo;;
      7) ver_relatorio_venda;;
      0) break;;
      *) echo "Opção inválida";;
    esac
    read -p "ENTER para continuar..."
  done
}
   
logar() {
  while true; do
    clear
    echo "========= LOGIN ANGOLA CARS ========="
    read -p "ID: " id
    read -s -p "Senha: " senha
    echo

    linha=$(grep "^$id;.*;$senha;" usuarios.csv)

    if [ -n "$linha" ]; then
      usuario=$(echo "$linha" | cut -d';' -f2)
      funcao=$(echo "$linha" | cut -d';' -f4)
      filial_id=$(echo "$linha" | cut -d';' -f7)

      # Salva sessão em arquivo
      echo "$id;$usuario;$filial_id" > .session

      # Buscar nome da filial (se houver)
      if [ -n "$filial_id" ]; then
        nome_filial=$(awk -F';' -v fid="$filial_id" 'NR>1 && $1==fid { print $2 }' filiais.csv)
        echo "Bem-vindo, $usuario – Filial: $nome_filial ($funcao)"
      else
        echo "Bem-vindo, $usuario ($funcao)"
      fi

      sleep 2

      case "$funcao" in
        Admin)
          if [ -n "$filial_id" ]; then
            menu_admin_filial "$nome_filial"
          else
            menu_admin
          fi
          ;;
        Recepcao) menu_recepcao ;;
        Vendas) menu_vendas ;;
        *)
          echo "Função desconhecida!"
          sleep 2
          ;;
      esac

      break  # Sai do loop após login válido
    else
      echo "ID ou senha inválidos!"
      read -p "Pressione ENTER para tentar novamente..."
    fi
  done
}


logar


