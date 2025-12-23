<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1>Rider</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a href="<?= base_url("home") ?>">Dashboard</a></li>
                    </ol>
                </div>
            </div>
        </div><!-- /.container-fluid -->
    </section>

    <section class="content">
        <div class="container-fluid">
            <div class="row">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">

                        <?php if($this->session->userdata('Role') ==1): ?>
                        <form action="<?= base_url('user-list') ?>" method="post" class="mb-3">
                            <div class="form-row align-items-end">
                                <div class="col-auto">
                                    <label>Company</label>
                                    <select name="company_select" class="form-control select2bs4">
                                        <option value="all">----- All Company -----</option>
                                        <?php foreach($list_company as $val): ?>
                                            <option value="<?= $val['ListCompanyID'] ?>"
                                                <?= (isset($_POST['company_select']) && $_POST['company_select'] == $val['ListCompanyID']) ? "selected" : "" ?>>
                                                <?= $val['CompanyName'] ?>
                                            </option>
                                        <?php endforeach; ?>
                                    </select>
                                </div>

                                <div class="col-auto">
                                    <button type="submit" class="btn btn-primary btn-sm">Submit</button>
                                </div>
                            </div>
                        </form>
                        <?php endif; ?>

                        <!-- ROW 2: Tombol Excel + Add -->
                        <div class="d-flex justify-content-between align-items-center">

                            <div class="d-flex" style="gap: 10px;">
                                <!-- Import Excel -->
                                <form id="import_excel_form" enctype="multipart/form-data">
                                    <label for="import_excel" class="btn btn-success btn-sm mb-0">
                                        <i class="fa fa-file-excel"></i> Import Excel
                                    </label>
                                    <input type="file" id="import_excel" name="import_excel" accept=".xls,.xlsx" hidden>
                                </form>

                                <!-- Download Example -->
                                <a style="height: fit-content; padding: .31rem .5rem;" href="<?= base_url('assets/dist/Example Excel Upload Rider.xlsx') ?>"
                                    class="btn btn-primary btn-sm mb-0" download>
                                    <i class="fa fa-download"></i> Download Example Excel
                                </a>
                            </div>

                            <!-- Button Add -->
                            <button class="btn btn-sm btn-primary" style="padding: .31rem .5rem;" id="add_user" type="button">
                                Add Rider
                            </button>
                        </div>

                    </div>

                    <div class="card-body">
                        <table class="table table-bordered table-striped" id="example3" style="width: 100%;">
                            <thead>
                                <tr class="text-center">
                                    <th style="width: 10%;">No</th>
                                    <th>Company</th>
                                    <th>Rider Name</th>
                                    <th>Email</th>
                                    <th>Phone Number</th>
                                    <th style="width: 15%;">Action</th>
                                </tr>
                            </thead>

                            <tbody>
                                <?php $no = 1; foreach($user as $val): ?>
                                <tr class="text-center">
                                    <td><?= $no++ ?></td>
                                    <td><?= $val['CompanyName'] ?></td>
                                    <td><?= $val['Fullname'] ?></td>
                                    <td><?= $val['Email'] ?></td>
                                    <td><?= $val['PhoneNumber'] ?></td>
                                    <td>
                                        <button data-userid="<?= $val['UserID'] ?>" class="btn btn-warning btn-sm buttonEditUser">
                                            <i class="fas fa-edit"></i>
                                        </button>

                                        <button data-userid="<?= $val['UserID'] ?>" data-email="<?= $val['Email'] ?>"
                                            class="btn btn-danger btn-sm buttonDeleteUser">
                                            <i class="fas fa-trash"></i>
                                        </button>
                                    </td>
                                </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                        <!-- ./card-body -->

                        <!-- /.card-footer -->
                    </div>
                    <!-- /.card -->
                </div>
                <!-- /.col -->
            </div>
            <!-- /.row -->
        </div>
        <!--/. container-fluid -->
    </section>
</div>

<div class="modal fade" id="modal" tabindex="-1" role="dialog" aria-labelledby="modalAddLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg" role="document">
        <!-- bisa ganti modal-lg ke modal-sm/modal-xl -->
        <div class="modal-content">

            <!-- Header -->
            <div class="modal-header">
                <h5 class="modal-title" id="modalAddLabel"></h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>

            <!-- Body -->
            <div class="modal-body">
                <form id="formAddUser" method="post">
                    <div class="form-group <?= ($this->session->userdata('Role') != 1) ? "d-none" : "" ?>">
                        <label for="email">Select Company</label>
                         <select name="company_selected" class="form-control select2For_modal" id="company_selected" required>
                            <option value="">---- Select Company ----</option>
                            <?php foreach($list_company as $val): ?>
                                <option value="<?= $val['ListCompanyID'] ?>" <?= ($this->session->userdata('CompanyID') == $val['ListCompanyID']) ? "selected" : "" ?> <?= ($this->session->userdata('Role') != 1) ?  "disabled" : "" ?> ><?= $val['CompanyName'] ?></option>
                            <?php endforeach; ?>
                         </select>
                    </div>
                    <div class="form-group">
                        <input type="hidden" id="user_id" name="user_id">
                        <label for="fullname">Fullname</label>
                        <input type="text" class="form-control" id="fullname" name="fullname"
                            placeholder="Enter Full Name">
                    </div>

                    <!-- New feature where the riders will have two roles. One is Rider only and one is a viewing user. -Kian -->
                    <div class="form-group">
                        <label for="email">Select User Role</label>
                         <select name="user_role" class="form-control select2For_modal" id="user_role" required>
                            <option value="">---- Select Role ----</option>
                            <option value="monitor">Monitor</option>
                            <option value="field">Field</option>
                         </select>
                    </div>
                    
                    <div class="form-group">
                        <label for="email">Email</label>
                        <input type="email" class="form-control" id="email" name="email" placeholder="Enter Email">
                    </div>

                    <div class="form-group">
                        <label for="pass">Password</label>
                        <input type="password" class="form-control" id="pass" name="pass">
                    </div>

                    <div class="form-group">
                        <label for="phone_number">Phone Number</label>
                        <div class="input-group">
                            <div class="input-group-prepend">
                                <span class="input-group-text">+63</span>
                            </div>
                            <input type="text" class="form-control" id="phone" name="phone"
                                placeholder="Enter Phone Number">
                        </div>
                    </div>
                </form>

                <!-- <div class="container_notes">
                    <p class="mb-0"><strong>Notes</strong> : By adding a Rider, the Rider can <strong>log in</strong>
                        using the
                        <strong>registered email</strong> and the
                        default <strong>password</strong> (12345).
                    </p>
                </div> -->
            </div>

            <!-- Footer -->
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">Close</button>
                <button type="submit" form="formAddUser" class="btn btn-sm btn-primary">Save</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="modal_delete" tabindex="-1" role="dialog" aria-labelledby="modalAddLabel"
    aria-hidden="true">
    <div class="modal-dialog modal-md" role="document">
        <!-- bisa ganti modal-lg ke modal-sm/modal-xl -->
        <div class="modal-content">

            <!-- Header -->
            <div class="modal-header">
                <h5 class="modal-title" id="modalDeleteLabel"></h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>

            <!-- Body -->
            <div class="modal-body">
                <form id="formDelete" method="post">
                    <input type="hidden" id="user_id" name="user_id">
                    <input type="hidden" id="current_job" name="current_job">
                    <p id="detail_reason_delete" class="mb-0"></p>
                    <span>Do you want to delete the rider : <strong id="email_users"></strong></span>
                </form>
            </div>

            <!-- Footer -->
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">Close</button>
                <button type="submit" form="formDelete" class="btn btn-sm btn-primary">Delete</button>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/jquery"></script>

<script>
$(document).ready(function() {
    let buttonAddUser = $('#add_user');
    let buttonEditUser = $('.buttonEditUser');
    let buttonDeleteUser = $('.buttonDeleteUser');
    let modal = $('#modal');
    let modalDelete = $('#modal_delete');
    let textHeaderModal = $("#modalAddLabel");
    let textHeaderModalDelete = $("#modalDeleteLabel");
    let formUser = $("#formAddUser");
    let formUserDelete = $("#formDelete");

    $('#phone').on('input', function() {
        // hapus semua karakter yang bukan angka
        this.value = this.value.replace(/[^0-9]/g, '');
    });

    // handle button add
    buttonAddUser.on('click', function(e) {
        e.preventDefault();
        modal.modal('show');
        modal.find('.container_notes').show();

        textHeaderModal.text('Add Rider');
        modal.find('#user_id').val('');
        modal.find('#user_role').val(''); // gets user_role input
        modal.find('#fullname').val('');
        modal.find('#email').val('');
        modal.find('#pass').val('');
        modal.find('#phone').val('');

        formUser.attr("action", '<?= base_url('create-user') ?>')
    });

    // handle button edit
    buttonEditUser.on('click', function(e) {
        e.preventDefault();
        modal.modal('show');
        modal.find('.container_notes').hide();

        let userID = $(this).data('userid');

        textHeaderModal.text('Edit Rider');
        formUser.attr("action", '<?= base_url('edit-user') ?>');

        $.ajax({
            url: '<?= base_url('User/getUser') ?>',
            method: 'post',
            data: {
                userID: userID
            },
            dataType: 'json',
            success: function(response) {

                // console.log(response)

                let phoneNumber = response.PhoneNumber.replace(/^\+63/, '');
                phoneNumber = parseInt(phoneNumber);

                modal.find('#user_id').val(response.UserID);
                modal.find('#fullname').val(response.Fullname);
                modal.find('#company_selected').val(response.ListCompanyID).trigger('change');
                modal.find('#email').val(response.Email);
                modal.find('#pass').val(response.Password);
                modal.find('#phone').val(phoneNumber);
            },
        })

    })


    // handle button delete
    buttonDeleteUser.on('click', function(e) {
        e.preventDefault();
        modalDelete.modal('show');
        textHeaderModalDelete.text('Delete Rider')
        formUserDelete.attr("action", '<?= base_url('delete-user') ?>');

        let userID = $(this).data('userid');
        let email = $(this).data('email');

        $.ajax({
            url: '<?= base_url("User/get_data_user_for_delete/") ?>' + userID,
            dataType: "json", 
            success: function(resp) {
                modalDelete.find('#user_id').val(userID);
                modalDelete.find('#email_users').text(email);
                
                if(resp != null) {
                    var text = `This rider currently has an ongoing job. : ${resp.JobName}`
                    modalDelete.find('#detail_reason_delete').text(text);

                    $("#current_job").val(resp.JobID);
                } else {
                    var text = ``
                    modalDelete.find('#detail_reason_delete').text(text);

                    $("#current_job").val('');
                }
            } ,
        })

       
    });

    $('#import_excel').on('change', function() {
        var file = this.files[0];

        if (!file) return;

        var allowedExtensions = /(\.xls|\.xlsx)$/i;
        if (!allowedExtensions.exec(file.name)) {
            Swal.fire({
                icon: 'error',
                title: 'Invalid file!',
                text: 'Please upload an Excel file (.xls or .xlsx)',
            });
            $(this).val('');
            return;
        }

        var formData = new FormData($('#import_excel_form')[0]);

        $.ajax({
            url: '<?= base_url("User/import_excel"); ?>', // ganti sesuai endpoint
            type: 'POST',
            data: formData,
            processData: false,
            contentType: false,
            dataType: 'json',
            beforeSend: function() {
                Swal.fire({
                    title: 'Uploading...',
                    text: 'Please wait a moment',
                    allowOutsideClick: false,
                    showConfirmButton: false,
                    didOpen: () => {
                        Swal.showLoading();
                    }
                });
            },
            success: function(response) {
                Swal.close();

                if(response.status) {

                    if(response.label == "success") {

                        Swal.fire({
                            icon: 'success',
                            title: 'Upload Successful!',
                            html: response.message,
                            showConfirmButton: true,
                            confirmButtonText: 'OK',
                            customClass: {
                                confirmButton: 'btn btn-sm btn-primary'
                            },
                            buttonsStyling: false // wajib biar class bootstrap nya jalan
                        }).then(() => {
                            location.reload();
                        });

                    } else {
                        Swal.fire({
                            icon: 'success',
                            title: 'Upload Successful!',
                            html: response.message,
                            showConfirmButton: true,
                            confirmButtonText: 'OK',
                            customClass: {
                                confirmButton: 'btn btn-sm btn-primary'
                            },
                            buttonsStyling: false // wajib biar class bootstrap nya jalan
                        }).then(() => {
                            location.reload();
                        });

                    }
                }

                // console.log(response);
                $('#import_excel').val(''); // reset input
            },
            error: function(xhr, status, error) {
                Swal.close();
                Swal.fire({
                    icon: 'error',
                    title: 'Upload Failed!',
                    text: 'Something went wrong: ' + error
                });
                $('#import_excel').val('');
            }
        });
    });


});
</script>