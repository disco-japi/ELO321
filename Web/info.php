<?php require "base.php";
if ($login) {
	$id = $_GET["id"];
	$tab = $_GET["tab"];
	$fun = !($_GET["type"] == "Error");
	$sql = $fun ? "select * from Vista_Publicaciones_Usuario where id_elemento = $id and tipo COLLATE utf8mb4_unicode_ci = 'Funcionalidad'" : "select * from Vista_Publicaciones_Usuario where id_elemento = $id and tipo COLLATE utf8mb4_unicode_ci = 'Error'";
	$query = $conn->query($sql);
	if ($query != false) {
		$data = $query->fetch_array();
		$estado = $data["estado"] ?>
		<div class="modal-header">
			<h5 class="modal-title"><?php echo $data["titulo"]; ?></h5>
			<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
		</div>
		<div class="modal-body">
			<p><strong>Tipo:</strong> <?php echo $data["tipo"]; ?></p>
			<p><strong>ID instacia:</strong> <?php echo $data["id_elemento"]; ?></p>
			<p><strong>RUT creador:</strong> <?php echo $data["rut_usuario"]; ?></p>
			<p><strong>Descipción:</strong> <?php echo $data["descripcion"]; ?></p>
			<p><strong>Tópico:</strong> <?php echo $data["topico"]; ?></p>
			<p><strong>Estado:</strong> <?php echo $data["estado"]; ?></p>
			<p><strong>Fecha:</strong> <?php echo $data["fecha"]; ?></p>
			<?php if ($fun) { ?>
				<p><strong>Ambiente:</strong> <?php echo $data["ambiente"]; ?></p>
				<hr class="my-4" />
			<?php
				$critsReq = "select descripcion from CriteriosAceptacion where id_funcionalidad = $id";
				$crits = $conn->query($critsReq);
				$i = 1;
				while ($crit = $crits->fetch_array()) {
					$crittext = $crit["descripcion"];
					echo "<p><strong>Criterio $i:</strong> $crittext</p>";
					$i++;
				}
			} ?>
			<hr class="my-4" />
			<h5>Reseñas</h5>
			<?php
			$comments = $fun ? "select * from Resena_Funcionalidad where id_funcionalidad = $id" : "select * from Resena_Error where id_error = $id";
			$resQuery = $conn->query($comments);
			if ($resQuery != false) {
				if ($resQuery->num_rows > 0) { ?>
					<table class="table">
						<thead>
							<tr>
								<th scope="col">ID</th>
								<th scope="col">Administrador</th>
								<th scope="col">Observación</th>
								<th scope="col">Fecha Creación</th>
							</tr>
						</thead>
						<tbody>
							<?php
							while ($resena = $resQuery->fetch_array()) {
								echo "<tr>";
								echo "<th scope='row'>" . $resena["id"] . "</th>";
								echo "<td>" . $resena["rut_ingeniero"] . "</td>";
								echo "<td>" . $resena["observacion"] . "</td>";
								echo "<td>" . $resena["fecha_creacion"] . "</td>";
								echo "</tr>";
							} ?>
						</tbody>
					</table>
				<?php
				} else {
					echo "<p>Esta solicitud no tiene reseñas</p>";
				}
				if ($administrador) { ?>
					<form class="col-12 col-lg-auto mb-0 mb-lg-0 me-lg-3" action="dashboard.php?tab=<?php echo $tab; ?>" method="POST">
						<input type="hidden" name="sendresena" value="1">
						<input type="hidden" name="resenaid" value="<?php echo $id; ?>">
						<?php if ($fun) echo "<input type='hidden' name='resenafun' value='1'>"; ?>
						<div class="input-group mb-0">
							<input minlength="3" required="" class="form-control form-control-dark" placeholder="Escriba su reseña" name="resena">
							<button class="btn btn-primary" type="submit">Enviar reseña <i class="bi bi-pencil-square"></i></button>
						</div>
					</form>
				<?php }
			} else { ?>
				<div class="alert alert-danger" role="alert">Error: <?php echo $conn->error; ?></div>
			<?php }
			?>
		</div>
		<div class="modal-footer">
			<?php if ($rut == $data["rut_usuario"] && $estado != "En Progreso") { ?>
				<button class="btn btn-primary d-inline-flex align-items-center" onclick="showEdit(this);" data-fila="<?php echo $id; ?>" data-fun="<?php echo $fun; ?>" type="button">Editar <i class="bi bi-pencil"></i></button>
			<?php } ?>
		</div>
	<?php } else { ?>
		<div class="alert alert-danger" role="alert">Error desconocido</div>
<?php }
} ?>