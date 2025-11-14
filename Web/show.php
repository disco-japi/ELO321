<script>
  function showDelete(fila) {
    document.getElementById("delid").value = fila.getAttribute("data-fila");
    document.getElementById("deltype").value = fila.getAttribute("data-error");
    var removeModal = new bootstrap.Modal(document.getElementById('ModalRemove'), {
      keyboard: false
    });


    removeModal.show();
  }

  function showInfo(fila) {
    let nFila = fila.getAttribute("data-fila");
    let fError = fila.getAttribute("data-error");
    const infoContent = document.getElementById("info-content");
    fetch("info.php?type=" + encodeURIComponent(fError) + "&id=" + encodeURIComponent(nFila) + "&tab=" + encodeURIComponent(<?php echo $tab; ?>))
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
    let fun = 0;
    if (fila.getAttribute("data-fun") != "") {
      fun = 1;
    }
    const editContent = document.getElementById("info-content");
    fetch("edit.php?fun=" + encodeURIComponent(fun) + "&id=" + encodeURIComponent(nFila) + "&tab=" + encodeURIComponent(<?php echo $tab; ?>))
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

  }
</script>
<?php
if (array_key_exists("edit", $_POST)) {
  $EID = $_POST["id"];
  $nombre = $_POST["titulo"];
  $descripcion = $_POST["desc"];
  $estado = $_POST["est"];
  if (array_key_exists("editfun", $_POST)) {
    $ambiente = $_POST["amb"];
    $cr1 = $_POST["cr1"];
    $cr2 = $_POST["cr2"];
    $cr3 = $_POST["cr3"];
  }
  $sql = array_key_exists("editfun", $_POST) ? "call modificar_funcionalidad($EID,'$rut','$nombre','$descripcion',$ambiente,$estado,'$cr1','$cr2','$cr3')" : "call actualizar_error($EID,'$nombre','$descripcion',$estado,'$rut')";
  $query = $conn->query($sql);
  if ($query != false) {
    $info = "Solicitud editada";
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
  $sql = array_key_exists("resenafun", $_POST) ? "call crear_resena_funcionalidad($RID,'$rut','$resena')" : "call crear_resena_error($RID,'$rut','$resena')";
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
  if ($deltype == "Error") {
    $sql = "call eliminar_error('$id', '$rut')";
  } else {
    $sql = "call eliminar_funcionalidad('$id', '$rut')";
  }
  $query = $conn->query($sql);
  if ($query != false) {
    $info = "Elemento eliminado exitosamente";
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
if ($tab == 1) {
  $sql = "select * from Vista_Publicaciones_Usuario where tipo COLLATE utf8mb4_unicode_ci = 'Funcionalidad'";
?>
  <h2>Solicitudes de funcionalidad</h2>
<?php //Compras Administrador
} else if ($tab == 2) {
  $sql = "select * from Vista_Publicaciones_Usuario where tipo COLLATE utf8mb4_unicode_ci = 'Error'";
?>
  <h2>Solicitudes de gestión de error</h2>
<?php //Propias administrador
} else if ($tab == 3) {
  $sql = "select * from Vista_Asignaciones_Ingeniero where rut_ingeniero = '$rut'";
?>
  <h2>Solicitudes asignadas a mi</h2>
<?php
  //Funcionalidades
} else if ($tab == 4) {
  $sql = "select * from Vista_Publicaciones_Usuario where rut_usuario = '$rut' and tipo COLLATE utf8mb4_unicode_ci = 'Funcionalidad'";
?>
  <h2>Mis solicitudes de funcionalidad</h2>
<?php //Compras
} else if ($tab == 5) {
  $sql = "select * from Vista_Publicaciones_Usuario where rut_usuario = '$rut' and tipo COLLATE utf8mb4_unicode_ci = 'Error'";
?>
  <h2>Mis solicitudes de gestión de error</h2>
<?php //Busqueda 
} else if ($tab == 7) {
  $searchword = $_GET["search"];
  $sql = "select * from Vista_Publicaciones_Usuario where titulo like '%$searchword%'";
?>
  <h2>Resultados busqueda "<?php echo $searchword; ?>"</h2>
<?php //Busqueda avanzada
} else if ($tab == 8) {
  $searchword = $_GET["titulo"];
  $date = $_GET["reciente"];
  $sql = "select * from Vista_Publicaciones_Usuario where titulo like '%$searchword%' and fecha > '$date' ";
  if ($_GET["esp"] != "") {
    $get = $_GET['esp'];
    $sql = $sql . "and topico = '$get' ";
  }
  if ($_GET["ambs"] != "") {
    $get = $_GET['ambs'];
    $sql = $sql . "and ambiente = '$get' ";
  }
  if ($_GET["estado"] != "") {
    $get = $_GET['estado'];
    $sql = $sql . "and estado = '$get' ";
  }
?>
  <h2>Resultados busqueda avanzada "<?php echo $searchword; ?>"</h2>
  <?php }
$query = $conn->query($sql);
if ($query != false) {
  if ($query->num_rows > 0) {
  ?>
    <div class="table-responsive">
      <table class="table align-middle border rounded-3 shadow-lg">
        <thead>
          <tr>
            <?php if ($tab == 3 || $tab == 7 || $tab == 8) echo '<th scope="col">Tipo</th>'; ?>
            <th scope="col">ID</th>
            <?php if ($tab == 7) echo '<th scope="col">Autor</th>'; ?>
            <th scope="col">Título</th>
            <th scope="col">Descripción</th>
            <?php if ($tab == 1 || $tab == 4 || $tab == 3 || $tab == 7) echo '<th scope="col">Ambiente</th>'; ?>
            <th scope="col">Tópico</th>
            <?php if ($tab != 8) { ?>
              <th scope="col">Estado</th>
              <th scope="col">Fecha<?php if ($tab == 3) echo " asignación" ?></th>
              <th scope="col"></th>
            <?php } ?>
          </tr>
        </thead>
        <tbody>
          <?php
          while ($fila = $query->fetch_array()) { ?>
            <tr>
              <?php if ($tab == 3 || $tab == 7 || $tab == 8) echo "<th>" . $fila["tipo"] . "</th>"; ?>
              <th scope="row"><?php echo $fila["id_elemento"]; ?></th>
              <?php if ($tab == 7) echo "<td>" . $fila["nombre_usuario"] . "</td>"; ?>
              <td><?php echo $fila["titulo"]; ?></td>
              <td><?php echo $fila["descripcion"]; ?></td>
              <?php if ($tab == 1 || $tab == 4 || $tab == 3 || $tab == 7) echo "<td>" . $fila['ambiente'] . "</td>"; ?>
              <td><?php echo $fila["topico"]; ?></td>
              <?php if ($tab != 8) { ?>
                <td><?php echo $fila["estado"]; ?></td>
                <?php if ($tab == 3) {
                ?><td><?php echo $fila["fecha_asignacion"]; ?></td>
                <?php } else { ?>
                  <td><?php echo $fila["fecha"]; ?></td>
                <?php } ?>
                <td>
                  <div class="btn-group" role="group" aria-label="tools">
                    <?php if (!$administrador && $tab != 7 && $fila["estado"] != "En Progreso") { ?>
                      <button class="btn btn-danger d-inline-flex align-items-center" onclick="showDelete(this);" data-fila="<?php echo $fila["id_elemento"]; ?>" data-error="<?php echo $fila["tipo"]; ?>" type="button">Eliminar <i class="bi bi-x-lg"></i></button>
                    <?php }
                    ?>
                    <button class="btn btn-primary d-inline-flex align-items-center" onclick="showInfo(this);" data-fila="<?php echo $fila["id_elemento"]; ?>" data-error="<?php echo $fila["tipo"]; ?>" type="button">Detalles <i class="bi bi-info-lg"></i></button>

                  </div>
                </td>
              <?php } ?>
            </tr><?php }
                  ?>
        </tbody>
      </table>
    </div>
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
            <form action="dashboard.php?tab=<?php echo $tab; ?>" method="post">
              <input type="hidden" name="delete" value="true" />
              <input type="hidden" name="delid" id="delid" value="" />
              <input type="hidden" name="deltype" id="deltype" value="" />
              <button type="submit" class="btn btn-danger">Eliminar <i class="bi bi-x-lg"></i></button>
            </form>
          </div>
        </div>
      </div>
    </div>
    </center>
    <div class="modal fade" id="ModalInfo" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog modal-lg">
        <div class="modal-content" id="info-content">
          <div class="modal-body text-center py-5">
            Cargando...
          </div>
        </div>
      </div>
    </div>
    <center>
    <?php
  } else { ?>
      <div class="container">
        <center>
          <div class="alert alert-primary" role="alert">
            No hay entradas en la base de datos que coincidan con tu criterio.
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
  ?>