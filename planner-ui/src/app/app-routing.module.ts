import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Routes } from '@angular/router';
import { DetailsComponent } from './details/details.component';
import { HomeComponent } from './home/home.component';
import { PhotosComponent } from './photos/photos.component';

const routes: Routes = [
  {path: '', component: HomeComponent},
  {path: 'details/:list', component: DetailsComponent, runGuardsAndResolvers: 'always'},
  {path: 'photos', component: PhotosComponent, runGuardsAndResolvers: 'always'}
];

@NgModule({
  imports: [
    CommonModule,
    RouterModule.forRoot(routes)
  ],
  exports: [
    RouterModule
  ],
  declarations: []
})
export class AppRoutingModule { }
