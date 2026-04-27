import {NgModule} from '@angular/core';
import {CommonModule} from '@angular/common';
import {AppComponent} from './app.component';
import {RouterModule, RouterOutlet} from '@angular/router';
import {BrowserModule} from '@angular/platform-browser';
import {routes} from './app.routes';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import {MatToolbar} from "@angular/material/toolbar";
import {MatIcon} from "@angular/material/icon";
import {MatButton, MatIconButton} from "@angular/material/button";
import {MatDrawer, MatDrawerContainer, MatDrawerContent} from "@angular/material/sidenav";
import {HTTP_INTERCEPTORS, provideHttpClient, withInterceptors} from '@angular/common/http';
import {AuthService} from './login/auth.service';
import {MatListItem, MatNavList} from '@angular/material/list';
import {
    MatAccordion,
    MatExpansionPanel,
    MatExpansionPanelDescription,
    MatExpansionPanelHeader,
    MatExpansionPanelTitle
} from '@angular/material/expansion';
import {MatCard} from '@angular/material/card';
import {authInterceptor} from './login/auth.interceptor';
import { FontAwesomeModule } from '@fortawesome/angular-fontawesome';


@NgModule({
  declarations: [AppComponent],
    imports: [
        BrowserModule,
        BrowserAnimationsModule,
        CommonModule,
        RouterModule.forRoot(routes),
        RouterOutlet,
        MatToolbar,
        MatIcon,
        MatIconButton,
        MatButton,
        MatDrawerContainer,
        MatDrawer,
        MatDrawerContent,
        MatNavList,
        MatListItem,
        MatExpansionPanelDescription,
        MatExpansionPanelTitle,
        MatExpansionPanelHeader,
        MatExpansionPanel,
        MatCard,
        MatAccordion,
        FontAwesomeModule,
    ],
  bootstrap: [AppComponent],
  providers: [
    AuthService,
    provideHttpClient(
      withInterceptors([authInterceptor])
    )
  ]
})
export class AppModule {
}
