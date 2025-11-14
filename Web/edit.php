<?php require "base.php";
if ($login) {
	$id = $_GET["id"];
?>
	<div class="modal-header">
		<h5>Editando solicitud de venta <?php echo " n° " . $id; ?></h5>
	</div>
	<form action="dashboard.php?tab=<?php echo $tab; ?>" method="POST">
		<div class=" modal-body">
			<input type="hidden" name="edit" value="1" />
			<input type="hidden" name="id" value="<?php echo $id; ?>" />
			<div id="est">
				<label for="est" class="form-label">Estado</label><br>
				<select class="form-select mb-3" name="est">
					<option value="1">Abierto</option>
					<option value="2">En Progreso</option>
					<option value="3">Resuelto</option>
					<option value="4">Cerrado</option>
				</select>
			</div>
		</div>

		<div class="modal-footer">
			<button type="submit" class="btn btn-primary">Enviar <i class="bi bi-send"></i></button>
			<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>

		</div>
	</form>
<?php } ?>