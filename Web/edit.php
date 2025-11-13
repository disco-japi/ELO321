<?php require "base.php";
if ($login) {
	$id = $_GET["id"];
	$fun = intval($_GET["fun"]);
?>
	<div class="modal-header">
		<h5>Editando solicitud de <?php echo ($fun ? "funcionalidad" : "error") . " n° " . $id; ?></h5>
	</div>
	<form action="dashboard.php?tab=<?php echo $tab; ?>" method="POST">
		<div class=" modal-body">
			<input type="hidden" name="edit" value="1" />
			<input type="hidden" name="id" value="<?php echo $id; ?>" />
			<div class="form-floating mb-3"><input class="form-control" type="text" minlength="20" maxlength="100" class="form-control" label="titulo" name="titulo" id="titulo" placeholder="Título de la solicitud" /><label for="titulo">Título</label></div>
			<div class="form-floating mb-3"><textarea label="desc" class="form-control" name="desc" id="desc" placeholder="Descripción" minlength="20" maxlength="200" rows="4" cols="50"></textarea><label class="form-label" for="desc">Descripción</label></div>
			<div id="est">
				<label for="est" class="form-label">Estado</label><br>
				<select class="form-select mb-3" name="est">
					<option value="1">Abierto</option>
					<option value="2">En Progreso</option>
					<option value="3">Resuelto</option>
					<option value="4">Cerrado</option>
				</select>
			</div>
			<?php if ($fun) { ?>
				<input type="hidden" name="editfun" value="1" />
				<div id="amb">
					<label class="form-label" for="ambs">Selecciona un ambiente de desarrollo</label><br>
					<select label="ambs" class="form-select" name="amb">
						<option value="1">Web</option>
						<option value="2">Movil</option>
					</select><br>
					<div class="form-floating mb-3"><input class="form-control" maxlength="150" type="text" label="criterio1" name="cr1" id="criterio1" placeholder="Criterio 1"><label for="criterio1">Criterio 1</label></div>
					<div class="form-floating mb-3"><input class="form-control" maxlength="150" type="text" label="criterio2" name="cr2" id="criterio2" placeholder="Criterio 2"><label for="criterio2">Criterio 2</label></div>
					<div class="form-floating mb-3"><input class="form-control" maxlength="150" type="text" label="criterio3" name="cr3" id="criterio3" placeholder="Criterio 3"><label for="criterio3">Criterio 3</label></div>
				</div>
			<?php } ?>
		</div>

		<div class="modal-footer">
			<button type="submit" class="btn btn-primary">Enviar <i class="bi bi-send"></i></button>
			<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>

		</div>
	</form>
<?php } ?>