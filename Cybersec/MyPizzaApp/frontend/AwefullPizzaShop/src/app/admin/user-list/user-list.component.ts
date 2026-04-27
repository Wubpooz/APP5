import {Component, OnInit} from '@angular/core';
import {MatDialog} from '@angular/material/dialog';
import {User} from '../types/user';
import {UserEditDialogComponent} from '../user-edit-dialog/user-edit-dialog.component';
import {UserService} from '../user.service';

@Component({
  selector: 'app-user-list',
  templateUrl: './user-list.component.html',
  styleUrl: './user-list.component.scss'
})
export class UserListComponent implements OnInit {
  displayedColumns: string[] = ['name', 'email', 'role', 'actions'];
  users: User[] = [];

  constructor(public dialog: MatDialog, private userService: UserService) {
  }

  ngOnInit() {
    this.userService.getUsers().subscribe({
      next: data => {
        this.users = data
      }
    })
  }

  // Open the dialog to edit the user
  editUser(user: User): void {
    const dialogRef = this.dialog.open(UserEditDialogComponent, {
      width: '400px',
      data: {...user}, // Pass a copy of the user data
    });

    dialogRef.afterClosed().subscribe((result: User | undefined) => {
      if (result) {
        this.userService.editUser(result.id,result.name,result.email,result.role).subscribe({
          next: data => {
            this.userService.getUsers().subscribe({next: data => this.users = data})
          }
        })
        // Update the user list with the new details
        const index = this.users.findIndex(u => u.id === user.id);
        if (index !== -1) {
          this.users[index] = result;
          this.users = [...this.users]; // mandatory for angular change detector to update table
        }
      }
    });
  }
}
