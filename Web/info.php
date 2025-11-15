<?php require "base.php";
$id = $_GET["id"];
$tab = $_GET["tab"];
$sql = "select * from Vista_Items where id = $id";
$query = $conn->query($sql);
if ($query != false) {
	$data = $query->fetch_array(); ?>
	<div class="modal-header">
		<h5 class="modal-title"><?php echo $data["nombre"]; ?></h5>
		<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
	</div>
	<div class="modal-body">
		<?php $img = "img/" . $data['id'] . ".png"; ?>
		<img class="bd-placeholder-img card-img-top" src="<?php echo htmlspecialchars($img); ?>" alt="<?php echo htmlspecialchars($data['nombre']); ?>" style="max-width:60%; height:225px; object-fit:contain;">
		<p><strong>ID:</strong> <?php echo $data["id"]; ?></p>
		<p><strong>Tipo:</strong> <?php echo $data["nombre_tipo"]; ?></p>
		<p><strong>Descipción:</strong> <?php echo $data["descripcion"]; ?></p>
		<p><strong>Stock:</strong> <?php echo $data["stock"]; ?></p>
		<p><strong>Precio:</strong> <?php echo $data["precio"]; ?>$</p>
		<hr class="my-4" />
		<h5>Reseñas</h5>
		<?php
		$comments = "SELECT p.nombre, ri.comentario, ri.fecha_creacion FROM Resena_Item ri JOIN Persona p ON ri.rut_usuario = p.rut WHERE ri.id_item = $id";
		$resQuery = $conn->query($comments);
		if ($resQuery != false) {
			if ($resQuery->num_rows > 0) { ?>
				<table class="table">
					<thead>
						<tr>
							<th scope="col">Usuario</th>
							<th scope="col">Comentario</th>
							<th scope="col">Fecha Creación</th>
						</tr>
					</thead>
					<tbody>
						<?php
						while ($resena = $resQuery->fetch_array()) {
							echo "<tr>";
							echo "<td>" . $resena["nombre"] . "</td>";
							echo "<td>" . $resena["comentario"] . "</td>";
							echo "<td>" . $resena["fecha_creacion"] . "</td>";
							echo "</tr>";
						} ?>
					</tbody>
				</table>
			<?php
			} else {
				echo "<p>Este item no tiene comentarios</p>";
			}
			if ($login && !$administrador) { ?>
				<form class="col-12 col-lg-auto mb-0 mb-lg-0 me-lg-3" action="dashboard.php?tab=<?php echo $tab; ?>" method="POST">
					<input type="hidden" name="sendresena" value="1">
					<input type="hidden" name="resenaid" value="<?php echo $id; ?>">
					<div class="input-group mb-0">
						<input minlength="3" required="" class="form-control form-control-dark" placeholder="Escriba su comentario" name="resena">
						<button class="btn btn-primary" type="submit">Enviar comentario <i class="bi bi-pencil-square"></i></button>
					</div>
				</form>
			<?php }
		} else { ?>
			<div class="alert alert-danger" role="alert">Error: <?php echo $conn->error; ?></div>
		<?php }
		?>
	</div>
	<div class="modal-footer">
		<?php if ($login && !$administrador) { ?>
			<button class="btn btn-primary d-inline-flex align-items-center close" data-bs-dismiss="modal" onclick="showBuy(this);" data-fila="<?php echo $id; ?>" type="button">Comprar <i class="bi bi-cart"></i></button>
		<?php } ?>
	</div>
<?php } else { ?>
	<div class="alert alert-danger" role="alert">Error desconocido</div>
<?php
} ?>