<script>
  function showDelete(fila) {
    document.getElementById("delid").value = fila.getAttribute("data-fila");
    var removeModal = new bootstrap.Modal(document.getElementById('ModalRemove'), {
      keyboard: false
    });
    removeModal.show();
  }

  function showBuy(fila) {
    document.getElementById("buyid").value = fila.getAttribute("data-fila");
    var buyModal = new bootstrap.Modal(document.getElementById('ModalBuy'), {
      keyboard: false
    });
    buyModal.show();
  }

  function showInfo(fila) {
    let nFila = fila.getAttribute("data-fila");
    const infoContent = document.getElementById("info-content");
    fetch("info.php?id=" + encodeURIComponent(nFila) + "&tab=" + encodeURIComponent(<?php echo $tab; ?>))
      .then(response => {
        if (!response.ok) throw new Error("Error de red");
        return response.text();
      })
      .then(html => {
        infoContent.innerHTML = html;
      })
      .catch(err => {
        infoContent.innerHTML = `<div class="alert alert-danger">Error: ${err.message}</div>`;
      });
    var infoModal = new bootstrap.Modal(document.getElementById('ModalInfo'), {
      keyboard: false
    });
    infoModal.show();
  }

  function showEdit(fila) {
    let nFila = fila.getAttribute("data-fila");
    const editContent = document.getElementById("info-content");
    fetch("edit.php?id=" + encodeURIComponent(nFila) + "&tab=" + encodeURIComponent(<?php echo $tab; ?>))
      .then(response => {
        if (!response.ok) throw new Error("Error de red");
        return response.text();
      })
      .then(html => {
        editContent.innerHTML = html;
      })
      .catch(err => {
        editContent.innerHTML = `<div class="alert alert-danger">Error: ${err.message}</div>`;
      });
    var infoModal = new bootstrap.Modal(document.getElementById('ModalInfo'), {
      keyboard: false
    });
    infoModal.show();
  }
</script>
<?php
if (array_key_exists("edit", $_POST)) {
  $EID = $_POST["id"];
  $estado = $_POST["est"];
  $sql =  "call actualizar_compra($EID, $estado)";
  $query = $conn->query($sql);
  if ($query != false) {
    $info = "Venta modificada";
  } else {
    $info = "Error: $conn->error";
  } ?>
  <div class="container">
    <center>
      <div class="alert alert-warning" role="alert">
        <?php echo $info; ?>
      </div>
    </center>
  </div>
<?php
}
if (array_key_exists("sendresena", $_POST)) {
  $RID = $_POST["resenaid"];
  $resena = $_POST["resena"];
  $sql = "call crear_resena_item($RID,'$rut','$resena')";
  $query = $conn->query($sql);
  if ($query != false) {
    $info = "Reseña añadida";
  } else {
    $info = "Error: $conn->error";
  } ?>
  <div class="container">
    <center>
      <div class="alert alert-warning" role="alert">
        <?php echo $info; ?>
      </div>
    </center>
  </div>
<?php
}
if (array_key_exists("delete", $_POST)) {
  $id = intval($_POST["delid"]);
  $deltype = $_POST["deltype"];
  $info = "";
  $sql = "call eliminar_compra('$id')";
  $query = $conn->query($sql);
  if ($query != false) {
    $info = "Compra eliminada exitosamente";
  } else {
    $info = "Error: $conn->error";
  } ?>
  <div class="container">
    <center>
      <div class="alert alert-warning" role="alert">
        <?php echo $info; ?>
      </div>
    </center>
  </div>
<?php
}
if (array_key_exists("buy", $_POST)) {
  $id = intval($_POST["buyid"]);
  $info = "";
  $sql = "CALL registrar_compra('$id', '$rut',1)";
  $query = $conn->query($sql);
  if ($query != false) {
    $info = "Elemento comprado exitosamente";
  } else {
    $info = "Error: $conn->error";
  } ?>
  <div class="container">
    <center>
      <div class="alert alert-warning" role="alert">
        <?php echo $info; ?>
      </div>
    </center>
  </div>
<?php
}
$sql = '';
//Funcionalidades Administrador
if ($tab == 0) {
  $sql = "select * from Item ORDER BY RAND()";
?>
<?php } else if ($tab == 1) {
  $sql = "select * from Vista_Compras_Usuario";
?>
  <h2 class="fw-light">Ventas</h2>
<?php } else if ($tab == 3) {
  $sql = "select * from Vista_Items";
?>
  <h2 class="fw-light">Todos los Items</h2>
<?php } else if ($tab == 4) {
  $search = $_GET["search"];
  $sql = "select * from Vista_Items where nombre LIKE '%$search%'";
?>
  <h2 class="fw-light">Resultados busqueda "<?php echo $search; ?>"</h2>
<?php //Compras Usuario
} else if ($tab == 2) {
  $sql = "select * from Vista_Compras_Usuario where rut_usuario = '$rut'";
?>
  <h2 class="fw-light">Mis compras</h2>
<?php }
$query = $conn->query($sql);
if ($tab == 0 && $query != false) { ?>
  <section class="py-1 text-center container">
    <div class="row py-lg-5">
      <div class="col-lg-6 col-md-8 mx-auto">
        <h1 class="fw-light">Bienvenido a TeleFactory</h1>
        <p class="lead text-body-secondary">Mire los distintos productos que tenemos para satisfacer sus necesidades en tecnología.</p>
      </div>
    </div>
  </section>
  <div class="album py-3 bg-body-tertiary">
    <div class="container">
      <div class="row row-cols-1 row-cols-sm-2 row-cols-md-4 g-3">
        <?php if ($query->num_rows > 0) {
          while ($fila = $query->fetch_array()) {
        ?> <div class="col">
              <div class="card shadow-sm">
                <?php $img = "img/" . $fila['id'] . ".png"; ?>
                <img class="bd-placeholder-img card-img-top" src="<?php echo htmlspecialchars($img); ?>" alt="<?php echo htmlspecialchars($fila['nombre']); ?>" style="width:100%; height:225px; object-fit:cover;">
                <div class="card-body">
                  <p class="card-text"><?php echo $fila['nombre']; ?></p>
                  <div class="d-flex justify-content-between align-items-center">
                    <div class="btn-group">
                      <button type="button" onclick="showInfo(this);" data-fila="<?php echo $fila['id']; ?>" class="btn btn-sm btn-outline-primary">Ver</button>
                      <?php if ($login && !$administrador) { ?>
                        <button type="button" onclick="showBuy(this);" data-fila="<?php echo $fila['id']; ?>" class="btn btn-sm btn-outline-secondary">Comprar <i class="bi bi-cart"></i></button>
                      <?php } ?>
                    </div>
                    <?php echo $fila['precio']; ?>$
                  </div>
                </div>
              </div>
            </div><?php
                }
              } ?>
      </div>
    </div>
  </div>
  <?php } else if ($query != false) {
  if ($query->num_rows > 0) {
    if ($tab == 2 || $tab == 1) {
  ?>
      <div class="table-responsive">
        <table class="table align-middle border rounded-3 shadow-lg">
          <thead>
            <tr>
              <th scope="col">ID Compra</th>
              <th scope="col">ID Item</th>
              <?php if ($administrador) {
              ?> <th scope="col">RUT Comprador</th>
              <?php
              } ?>
              <th scope="col">Nombre Item</th>
              <th scope="col">Estado</th>
              <th scope="col">Fecha</th>
              <th scope="col"></th>
            </tr>
          </thead>
          <tbody>
            <?php while ($fila = $query->fetch_array()) { ?>
              <tr>
                <th scope="row"><?php echo $fila["id_compra"]; ?></th>
                <th scope="row"><?php echo $fila["id_item"]; ?></th>
                <?php if ($administrador) {
                ?> <td scope="col"><?php echo $fila["rut_usuario"]; ?></th>
                  <?php
                } ?>
                  <td><?php echo $fila["nombre_item"]; ?></td>
                  <td><?php echo $fila["estado"]; ?></td>
                  <td><?php echo $fila["fecha"]; ?></td>
                  <td>
                    <div class="btn-group" role="group" aria-label="tools">
                      <?php if ($administrador) { ?>
                        <button class="btn btn-warning d-inline-flex align-items-center" onclick="showEdit(this);" data-fila="<?php echo $fila["id_compra"]; ?>" type="button">Editar <i class="bi bi-pencil"></i></button>
                      <?php }
                      ?>
                      <button class="btn btn-primary d-inline-flex align-items-center" onclick="showInfo(this);" data-fila="<?php echo $fila["id_item"]; ?>" type="button">Detalles <i class="bi bi-info-lg"></i></button>
                    </div>
                  </td>
              </tr>
            <?php } ?>
          </tbody>
        </table>
      </div>
    <?php } else if ($tab == 3 || $tab == 4) { ?>
      <div class="table-responsive">
        <table class="table align-middle border rounded-3 shadow-lg">
          <thead>
            <tr>
              <th scope="col">ID Item</th>
              <th scope="col">Nombre Item</th>
              <th scope="col">Tipo</th>
              <th scope="col">Stock</th>
              <th scope="col">Precio</th>
              <th scope="col"></th>
            </tr>
          </thead>
          <tbody>
            <?php while ($fila = $query->fetch_array()) { ?>
              <tr>
                <th scope="row"><?php echo $fila["id"]; ?></th>
                <td><?php echo $fila["nombre"]; ?></td>
                <td><?php echo $fila["nombre_tipo"]; ?></td>
                <td><?php echo $fila["stock"]; ?></td>
                <td><?php echo $fila["precio"]; ?></td>
                <td>
                  <div class="btn-group" role="group" aria-label="tools">

                    <button class="btn btn-primary d-inline-flex align-items-center" onclick="showInfo(this);" data-fila="<?php echo $fila["id"]; ?>" type="button">Detalles <i class="bi bi-info-lg"></i></button>
                  </div>
                </td>
              </tr>
            <?php } ?>
          </tbody>
        </table>
      </div>
    <?php } else { ?>
      <div class="container">
        <center>
          <div class="alert alert-primary" role="alert">
            No hay compras registradas.
          </div>
        </center>
      </div>
    <?php }
  } else { ?>
    <div class="container">
      <div class="alert alert-danger" role="alert">
        <?php echo  "Error: " . $conn->error; ?>
      </div>
    </div>
  <?php
  }
  if ($administrador) {
  ?>
    <div class="modal fade" id="ModalRemove" tabindex="-1" aria-labelledby="RemoveModalLabel" aria-hidden="true">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" id="RemoveModalLabel">Borrar elemento</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body">
            Esta acción es irreversible
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
            <form action="index.php?tab=<?php echo $tab; ?>" method="post">
              <input type="hidden" name="delete" value="true" />
              <input type="hidden" name="delid" id="delid" value="" />
              <input type="hidden" name="deltype" id="deltype" value="" />
              <button type="submit" class="btn btn-danger">Eliminar <i class="bi bi-x-lg"></i></button>
            </form>
          </div>
        </div>
      </div>
    </div>
<?php }
} ?>
<div class="modal fade" id="ModalBuy" tabindex="-1" aria-labelledby="BuyModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="BuyModalLabel">Comprar Item</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        ¿Deseas comprar este elemento?
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
        <form action="index.php?tab=<?php echo $tab; ?>" method="post">
          <input type="hidden" name="buy" />
          <input type="hidden" name="buyid" id="buyid" value="" />
          <button type="submit" class="btn btn-primary">Comprar <i class="bi bi-cart"></i></button>
        </form>
      </div>
    </div>
  </div>
</div>
<div class="modal fade" id="ModalInfo" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-lg">
    <div class="modal-content" id="info-content">
      <div class="modal-body text-center py-5">
        Cargando...
      </div>
    </div>
  </div>
</div>