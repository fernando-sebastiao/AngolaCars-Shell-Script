# Arquivo: menu_carros.sh

cadastrar_carro() {
  clear
  echo "=== Cadastro de Carro ==="

  if [ ! -f carros.csv ]; then
    echo "id;marca;data_entrada;preco" > carros.csv
  fi

  ultimo_id=$(tail -n +2 carros.csv | cut -d';' -f1 | sort -n | tail -1)
  if [ -z "$ultimo_id" ]; then
    novo_id="01"
  else
    novo_id=$(printf "%02d" $((10#$ultimo_id + 1)))
  fi

  read -p "Marca: " marca
  read -p "Data de entrada (AAAA-MM-DD): " data_entrada
  read -p "Preço: " preco

  echo "$novo_id;$marca;$data_entrada;$preco" >> carros.csv

  echo "Carro cadastrado com sucesso! (ID: $novo_id)"
  sleep 2
}

listar_carros() {
  clear
  echo "===== LISTA DE CARROS CADASTRADOS ====="
  echo

  if [ ! -f carros.csv ]; then
    echo "Arquivo carros.csv não encontrado!"
    sleep 2
    return
  fi

  total=$(wc -l < carros.csv)
  if [ "$total" -le 1 ]; then
    echo "Nenhum carro cadastrado."
    sleep 2
    return
  fi

  IFS=";" read -r idh march dh precoh < <(head -1 carros.csv)
  printf "%-5s %-12s %-15s %-15s\n" "$idh" "$march" "$dh" "PREÇO"

  tail -n +2 carros.csv | while IFS=";" read -r id marca data preco; do
    printf "%-5s %-12s %-15s %-15s\n" "$id" "$marca" "$data" "$preco"
  done

  echo
  read -p "ENTER para voltar..."
}

editar_carro() {
  clear
  echo "===== EDITAR CARRO ====="

  read -p "Informe o ID do carro que deseja editar: " id
  linha=$(tail -n +2 carros.csv | grep "^$id;")

  if [ -z "$linha" ]; then
    echo "Carro com ID $id não encontrado."
    sleep 2
    return
  fi

  marca_atual=$(echo "$linha" | cut -d';' -f2)
  data_atual=$(echo "$linha" | cut -d';' -f3)
  preco_atual=$(echo "$linha" | cut -d';' -f4)

  echo "Deixe em branco para manter o valor atual."
  read -p "Nova marca [$marca_atual]: " marca
  read -p "Nova data de entrada [$data_atual]: " data_entrada
  read -p "Novo preço [$preco_atual]: " preco

  marca="${marca:-$marca_atual}"
  data_entrada="${data_entrada:-$data_atual}"
  preco="${preco:-$preco_atual}"

  head -n 1 carros.csv > tmp_carros.csv
  tail -n +2 carros.csv | grep -v "^$id;" >> tmp_carros.csv
  echo "$id;$marca;$data_entrada;$preco" >> tmp_carros.csv
  mv tmp_carros.csv carros.csv

  echo "Carro com ID $id atualizado com sucesso."
  sleep 2
}

eliminar_carro() {
  clear
  echo "===== ELIMINAR CARRO ====="
  read -p "Informe o ID do carro a eliminar: " id
  linha=$(tail -n +2 carros.csv | grep "^$id;")

  if [ -z "$linha" ]; then
    echo "Carro com ID $id não encontrado."
    sleep 2
    return
  fi

  echo "Deseja realmente eliminar o carro com ID $id?"
  read -p "(s/n): " confirm
  if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
    head -n 1 carros.csv > tmp_carros.csv
    tail -n +2 carros.csv | grep -v "^$id;" >> tmp_carros.csv
    mv tmp_carros.csv carros.csv
    echo "Carro eliminado com sucesso."
  else
    echo "Operação cancelada."
  fi
  sleep 2
}

menu_carros() {
  while true; do
    clear
    echo "===== MENU DE CARROS ====="
    echo "[1] Cadastrar carro"
    echo "[2] Listar carros"
    echo "[3] Editar carro"
    echo "[4] Eliminar carro"
    echo "[0] Voltar"
    read -p "Opção: " op
    case $op in
      1) cadastrar_carro ;;
      2) listar_carros ;;
      3) editar_carro ;;
      4) eliminar_carro ;;
      0) break ;;
      *) echo "Opção inválida!"; sleep 1 ;;
    esac
  done
}
