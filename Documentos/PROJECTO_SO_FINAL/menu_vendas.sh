
listar_carros() {
  clear
  echo "=== LISTAGEM DE CARROS ==="

  # Verifica se o usuário está autenticado
  if [ ! -f .session ]; then
    echo "Erro: usuário não autenticado."
    sleep 2
    return
  fi

  # Lê dados da sessão
  IFS=";" read -r USER_ID USER_NOME USER_FILIAL_ID < .session

  # Define o nome do arquivo e filial_id conforme o usuário
  if [ "$USER_ID" = "1" ]; then
    nome_arquivo="carros.csv"
    nome_filial=""
  else
    nome_filial=$(awk -F';' -v fid="$USER_FILIAL_ID" 'NR>1 && $1==fid { print $2 }' filiais.csv)
    nome_filial_formatado=$(echo "$nome_filial" | tr -d '[:space:]')
    nome_arquivo="carros${nome_filial_formatado}.csv"
  fi

  # Verifica se o arquivo existe
  if [ ! -f "$nome_arquivo" ]; then
    echo "Arquivo '$nome_arquivo' não encontrado para a filial '$nome_filial'."
    sleep 2
    return
  fi

  # Verifica se arquivo tem dados além do cabeçalho
  total_linhas=$(wc -l < "$nome_arquivo")
  if [ "$total_linhas" -le 1 ]; then
    echo "Nenhum carro cadastrado na filial '$nome_filial'."
    sleep 2
    return
  fi

  # Imprime cabeçalho formatado
  IFS=";" read -r idh marcah datah precoh idfilialh < <(head -1 "$nome_arquivo")
  printf "%-5s %-15s %-15s %-10s %-10s\n" "$idh" "$marcah" "$datah" "$precoh" "$idfilialh"

  # Imprime dados do arquivo
  tail -n +2 "$nome_arquivo" | while IFS=";" read -r id marca data preco id_filial; do
    printf "%-5s %-15s %-15s %-10s %-10s\n" "$id" "$marca" "$data" "$preco" "$id_filial"
  done

  echo
  read -p "ENTER para voltar..."
}

abrir_vendas() {
  if [ ! -f vendas.csv ]; then
    echo "Arquivo vendas.csv não encontrado!"
    sleep 2
    return
  fi

  xdg-open vendas.csv &

  echo "Abrindo arquivo vendas.csv no programa padrão..."
  sleep 2
}

criar_venda() {
  clear
  echo "===== REGISTRO DE VENDA ====="

  if [ ! -f .session ]; then
    echo "Erro: usuário não autenticado."
    sleep 2
    return
  fi

  # Ler dados da sessão
  IFS=";" read -r USER_ID USER_NOME USER_FILIAL_ID < .session

  # Determina nome do arquivo de carros da filial
  if [ "$USER_ID" = "1" ]; then
    nome_arquivo_carros="carrosSede.csv"
    filial_nome="Sede"
  else
    nome_filial=$(awk -F';' -v fid="$USER_FILIAL_ID" 'NR > 1 && $1 == fid { print $2 }' filiais.csv)
    nome_filial_formatado=$(echo "$nome_filial" | tr -d '[:space:]')
    nome_arquivo_carros="carros${nome_filial_formatado}.csv"
    filial_nome="$nome_filial"
  fi

  if [ ! -f "$nome_arquivo_carros" ]; then
    echo "Erro: Arquivo de carros da filial não encontrado: $nome_arquivo_carros"
    sleep 2
    return
  fi

  read -p "ID do carro vendido: " carro_id
  read -p "Nome do cliente: " cliente_nome

  # Verifica se o carro existe no arquivo correto
  linha_carro=$(grep "^$carro_id;" "$nome_arquivo_carros")
  if [ -z "$linha_carro" ]; then
    echo "Erro: Carro com ID $carro_id não encontrado na sua filial."
    sleep 2
    return
  fi

  preco_venda=$(echo "$linha_carro" | cut -d';' -f4)

  # Remove espaços extras
  carro_id=$(echo "$carro_id" | xargs)
  cliente_nome=$(echo "$cliente_nome" | xargs)
  preco_venda=$(echo "$preco_venda" | xargs)
  filial_nome=$(echo "$filial_nome" | xargs)
  USER_NOME=$(echo "$USER_NOME" | xargs)

  data_venda=$(date "+%Y-%m-%d %H:%M")

  nome_arquivo="vendas.csv"

  # Cria cabeçalho se não existir
  if [ ! -f "$nome_arquivo" ]; then
    echo "id_venda;carro_id;data_venda;preco_venda;cliente_nome;user_id;nome_funcionario;filial_nome" > "$nome_arquivo"
  fi

  # Gera novo id_venda
  ultimo_id=$(tail -n +2 "$nome_arquivo" | cut -d';' -f1 | sort -n | tail -1)
  if [ -z "$ultimo_id" ]; then
    novo_id="01"
  else
    novo_id=$(printf "%02d" $((10#$ultimo_id + 1)))
  fi

  # Salvar a venda
  echo "$novo_id;$carro_id;$data_venda;$preco_venda;$cliente_nome;$USER_ID;$USER_NOME;$filial_nome" >> "$nome_arquivo"
  echo "Venda registrada com sucesso no arquivo: $nome_arquivo"
  echo "ID da nova venda: $novo_id"   # <-- MENSAGEM COM O ID
  sleep 2
}


pesquisar_venda() {
  clear
  echo "===== PESQUISAR VENDA ====="

  # Verifica se o arquivo de vendas existe
  if [ ! -f vendas.csv ]; then
    echo "Arquivo de vendas não encontrado!"
    sleep 2
    return
  fi

  echo "Pesquisar por:"
  echo "[1] ID da Venda"
  echo "[2] Nome do Cliente"
  read -p "Escolha uma opção: " opcao

  case $opcao in
    1)
      read -p "Digite o ID da venda: " id_venda
      resultado=$(awk -F';' -v id="$id_venda" 'NR == 1 || $1 == id' vendas.csv)
      ;;
    2)
      read -p "Digite o nome do cliente (ou parte): " nome_cliente
      resultado=$(awk -F';' -v nome="$nome_cliente" 'NR == 1 || tolower($5) ~ tolower(nome)' vendas.csv)
      ;;
    *)
      echo "Opção inválida!"
      sleep 2
      return
      ;;
  esac

  echo
  if [ -z "$resultado" ] || [ "$(echo "$resultado" | wc -l)" -le 1 ]; then
    echo "Nenhuma venda encontrada."
  else
    echo "Resultado da pesquisa:"
    echo "$resultado" | column -t -s ';'
  fi

  echo
  read -p "ENTER para voltar..."
}

emitir_comprovativo() {
  clear
  echo "===== EMITIR COMPROVATIVO DE VENDA ====="

  if [ ! -f vendas.csv ]; then
    echo "Arquivo de vendas não encontrado."
    sleep 2
    return
  fi

  read -p "Digite o ID da venda: " id_venda

  linha=$(awk -F';' -v id="$id_venda" '$1 == id { print $0 }' vendas.csv)

  if [ -z "$linha" ]; then
    echo "Venda com ID $id_venda não encontrada."
    sleep 2
    return
  fi

  IFS=';' read -r id_venda carro_id data_venda preco_venda cliente_nome user_id nome_funcionario filial_nome <<< "$linha"

  # Buscar a marca do carro correspondente ao carro_id (pegando apenas uma linha)
  linha_carro=$(grep "^$carro_id;" carros*.csv 2>/dev/null | head -n 1)
  marca=$(echo "$linha_carro" | cut -d';' -f2)

  echo
  echo "---------------------------------------------"
  echo "           COMPROVATIVO DE VENDA             "
  echo "---------------------------------------------"
  echo "Venda Nº         : $id_venda"
  echo "Data da Venda    : $data_venda"
  echo "Cliente          : $cliente_nome"
  echo "Carro ID         : $carro_id"
  echo "Marca do Carro   : $marca"
  echo "Preço            : $preco_venda"
  echo "Atendido por     : $nome_funcionario"
  echo "Filial           : ${filial_nome:-Sede}"
  echo "---------------------------------------------"
  echo "         Obrigado por comprar na             "
  echo "              ANGOLA CARS                    "
  echo "---------------------------------------------"

  echo
  read -p "Deseja salvar como arquivo (comprovativo_$id_venda.txt)? (s/n): " salvar
  if [[ "$salvar" =~ ^[Ss]$ ]]; then
    mkdir -p ComprovativosVenda
    nome_arquivo="ComprovativosVenda/comprovativo_${id_venda}.txt"

    {
      echo "----------- COMPROVATIVO DE VENDA -----------"
      echo "Venda Nº         : $id_venda"
      echo "Data da Venda    : $data_venda"
      echo "Cliente          : $cliente_nome"
      echo "Carro ID         : $carro_id"
      echo "Marca do Carro   : $marca"
      echo "Preço            : $preco_venda"
      echo "Atendido por     : $nome_funcionario"
      echo "Filial           : ${filial_nome:-Sede}"
      echo "---------------------------------------------"
      echo "Obrigado por comprar na ANGOLA CARS"
    } > "$nome_arquivo"

    echo "Comprovativo salvo como '$nome_arquivo'"
  fi

  read -p "ENTER para voltar..."
}

ver_relatorio_venda() {
  clear
  echo "===== RELATÓRIO DE VENDAS POR FILIAL ====="

  # Verifica se o usuário está autenticado
  if [ ! -f .session ]; then
    echo "Erro: usuário não autenticado."
    sleep 2
    return
  fi

  # Lê dados da sessão
  IFS=";" read -r USER_ID USER_NOME USER_FILIAL_ID < .session

  if [ ! -f vendas.csv ]; then
    echo "Nenhuma venda registrada ainda."
    sleep 2
    return
  fi

  # Cabeçalho
  printf "%-6s %-10s %-17s %-15s %-20s %-10s\n" "ID" "Carro" "Data" "Preço" "Cliente" "Filial"
  echo "------------------------------------------------------------------------------------------"

  if [ "$USER_ID" = "1" ]; then
    # Usuário da sede vê tudo
    tail -n +2 vendas.csv | while IFS=";" read -r id_venda carro_id data_venda preco_venda cliente_nome _ _ filial_nome; do
      printf "%-6s %-10s %-17s %-15s %-20s %-10s\n" "$id_venda" "$carro_id" "$data_venda" "$preco_venda" "$cliente_nome" "${filial_nome:-Sede}"
    done
  else
    # Usuário de filial só vê sua filial
    nome_filial=$(awk -F';' -v id="$USER_FILIAL_ID" 'NR>1 && $1==id {print $2}' filiais.csv)
    tail -n +2 vendas.csv | while IFS=";" read -r id_venda carro_id data_venda preco_venda cliente_nome _ _ filial_nome; do
      if [[ "$filial_nome" == "$nome_filial" ]]; then
        printf "%-6s %-10s %-17s %-15s %-20s %-10s\n" "$id_venda" "$carro_id" "$data_venda" "$preco_venda" "$cliente_nome" "$filial_nome"
      fi
    done
  fi

  echo
  read -p "ENTER para voltar..."
}

ver_relatorio_venda() {
  clear
  echo "===== RELATÓRIO DE VENDAS POR FILIAL ====="

  # Verifica se o usuário está autenticado
  if [ ! -f .session ]; then
    echo "Erro: usuário não autenticado."
    sleep 2
    return
  fi

  # Lê dados da sessão
  IFS=";" read -r USER_ID USER_NOME USER_FILIAL_ID < .session

  if [ ! -f vendas.csv ]; then
    echo "Nenhuma venda registrada ainda."
    sleep 2
    return
  fi

  # Cabeçalho
  printf "%-6s %-10s %-17s %-15s %-20s %-10s\n" "ID" "Carro" "Data" "Preço" "Cliente" "Filial"
  echo "------------------------------------------------------------------------------------------"

  if [ "$USER_ID" = "1" ]; then
    # Usuário da sede vê tudo
    tail -n +2 vendas.csv | while IFS=";" read -r id_venda carro_id data_venda preco_venda cliente_nome _ _ filial_nome; do
      printf "%-6s %-10s %-17s %-15s %-20s %-10s\n" "$id_venda" "$carro_id" "$data_venda" "$preco_venda" "$cliente_nome" "${filial_nome:-Sede}"
    done
  else
    # Usuário de filial só vê sua filial
    nome_filial=$(awk -F';' -v id="$USER_FILIAL_ID" 'NR>1 && $1==id {print $2}' filiais.csv)
    tail -n +2 vendas.csv | while IFS=";" read -r id_venda carro_id data_venda preco_venda cliente_nome _ _ filial_nome; do
      if [[ "$filial_nome" == "$nome_filial" ]]; then
        printf "%-6s %-10s %-17s %-15s %-20s %-10s\n" "$id_venda" "$carro_id" "$data_venda" "$preco_venda" "$cliente_nome" "$filial_nome"
      fi
    done
  fi

  echo
  read -p "ENTER para voltar..."
}

menu_vendas() {
  while true; do
    clear
    echo "===== MENU VENDAS - ANGOLA CARS ====="
    echo "[1] Registrar venda"
    echo "[2] Listar carros disponiveis antes de vender"
    echo "[3] Emitir comprovativo de vendas"
    echo "[0] Sair"
    read -p "Opção: " op
    case $op in
      1) criar_venda;;
      2) listar_carros;;
      3) emitir_comprovativo;;
      0) break;;
      *) echo "Opção inválida";;
    esac
    read -p "ENTER para continuar..."
  done
  }
  
