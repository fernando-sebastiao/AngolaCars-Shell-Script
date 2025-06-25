#!/bin/bash

source ./menu_carros.sh
source ./menu_usuarios.sh
source ./menu_filial.sh

menu_admin() {
  while true; do
    clear
    echo "===== MENU ADMIN - ANGOLA CARS ====="
    echo "[1] Gerir carros"
    echo "[2] Gerir funcionarios(usuarios)"
    echo "[3] Gerir filial"
    echo "[4] Registrar venda"
    echo "[5] Ver relatório"
    echo "[0] Sair"
    read -p "Opção: " op
    case $op in
      1) menu_carros;;
      2) menu_usuarios;;
      3) menu_filial;;
      4) echo "→ Registrar venda (a implementar)";;
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
    echo "[1] Cadastrar carro"
    echo "[3] Registrar venda"
    echo "[4] Ver relatório"
    echo "[0] Sair"
    read -p "Opção: " op
    case $op in
      1) cadastrar_carro;;
      2) cadastrar_funcionario;;
      3) echo "→ Registrar venda (a implementar)";;
      4) echo "→ Ver relatório (a implementar)";;
      5) echo "→ Gerir usuários (a implementar)";;
      0) break;;
      *) echo "Opção inválida";;
    esac
    read -p "ENTER para continuar..."
  done
}

menu_vendas() {
  while true; do
    clear
    echo "===== MENU VENDAS - ANGOLA CARS ====="
    echo "[1] Ver catálogo de carros"
    echo "[2] Registrar venda"
    echo "[0] Sair"
    read -p "Opção: " op
    case $op in
      1) echo "Ver catálogo de vendas";;
      2) echo "→ Registrar venda (a implementar)";;
      0) break;;
      *) echo "Opção inválida";;
    esac
    read -p "ENTER para continuar..."
  done
  }
  
  menu_recepcao() {
  while true; do
    clear
    echo "===== MENU RECEPÇÃO - ANGOLA CARS ====="
    echo "[1] Apresentar carros"
    echo "[2] Registrar cliente interessado"
    echo "[0] Sair"
    read -p "Opção: " op
    case $op in
      1) echo "→ Apresentar carros (a implementar)";;
      2) echo "→ Registrar cliente (a implementar)";;
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

      # Buscar nome da filial (caso exista)
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

      break  # Sai do loop de login após sucesso
    else
      echo "ID ou senha inválidos!"
      read -p "Pressione ENTER para tentar novamente..."
    fi
  done
}

logar


