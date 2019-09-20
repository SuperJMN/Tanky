using System;
using System.Reactive;
using System.Reactive.Disposables;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Media;
using SuperJMN.MonoGame;
using SuperJMN.MonoGame.Common;
using TankyReloaded.Actors;

namespace TankyReloaded
{
    /// <summary>
    /// This is the main type for your game.
    /// </summary>
    public class GameApp : Game
    {
        SpriteBatch spriteBatch;
        private readonly Tanky tanky = new Tanky();
        private Texture2D background;
        private IStage stage;
        private readonly GraphicsDeviceManager graphics;
        private readonly KeyboardObserver keyboardObserver = new KeyboardObserver();
        private IDisposable weaponSwitcher;
        private readonly CompositeDisposable disposables = new CompositeDisposable();

        public GameApp()
        {
            graphics = new GraphicsDeviceManager(this);
            Content.RootDirectory = "Content";
            graphics.PreferredBackBufferWidth = 720;
            graphics.PreferredBackBufferHeight = 480;
            //graphics.ToggleFullScreen();

            weaponSwitcher = keyboardObserver.KeyDownChanged(Keys.F1).Subscribe(b => tanky.SwitchWeapon()).DisposeWith(disposables);
        }

        /// <summary>
        /// Allows the game to perform any initialization it needs to before starting to run.
        /// This is where it can query for any required services and load any non-graphic
        /// related content.  Calling base.Initialize will enumerate through any components
        /// and initialize them as well.
        /// </summary>
        protected override void Initialize()
        {
            base.Initialize();
        }

        /// <summary>
        /// LoadContent will be called once per game and is the place to load
        /// all of your content.
        /// </summary>
        protected override void LoadContent()
        {
            // Create a new SpriteBatch, which can be used to draw textures.
            spriteBatch = new SpriteBatch(GraphicsDevice);
            background = Content.Load<Texture2D>("Background");
            var song = Content.Load<Song>("bgm/ladynavigation");
            MediaPlayer.Play(song);
            MediaPlayer.Volume = 0.25F;
            MediaPlayer.IsRepeating = true;

            stage = new MainStage(Content, graphics.PreferredBackBufferWidth, graphics.PreferredBackBufferHeight);
            OnStageCreated(stage);
            Constants.GroundTop = (float) (graphics.GraphicsDevice.Viewport.Height * (1-(double)1/7));
        }

        private void OnStageCreated(IStage stage)
        {
            stage.Add(tanky);
        }

        /// <summary>
        /// UnloadContent will be called once per game and is the place to unload
        /// game-specific content.
        /// </summary>
        protected override void UnloadContent()
        {
            stage.Dispose();
            disposables.Dispose();
        }

        /// <summary>
        /// Allows the game to run logic such as updating the world,
        /// checking for collisions, gathering input, and playing audio.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Update(GameTime gameTime)
        {
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
                Exit();

            var kstate = Keyboard.GetState();
            keyboardObserver.Sample();

            if (kstate.IsKeyDown(Keys.Right))
            {
                tanky.Advance(gameTime.ElapsedGameTime);
            }
            else if (kstate.IsKeyDown(Keys.Left))
            {
                tanky.GoBack(gameTime.ElapsedGameTime);
            }

            if (kstate.IsKeyDown(Keys.Space))
            {
                tanky.ShootRequest();
            }

            if (kstate.IsKeyDown(Keys.Up))
            {
                if (tanky.Animation != TankyAnimation.Jump)
                {
                    tanky.JumpRequest();
                }
            }

            if (kstate.IsKeyUp(Keys.Left) && kstate.IsKeyUp(Keys.Right) && tanky.Animation != TankyAnimation.Jump)
            {
                tanky.StopRequest();
            }

            stage.Update(gameTime);

            base.Update(gameTime);
        }

        /// <summary>
        /// This is called when the game should draw itself.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Draw(GameTime gameTime)
        {
            spriteBatch.Begin();
            spriteBatch.Draw(background, GraphicsDevice.Viewport.Bounds, Color.White);
            stage.Draw(spriteBatch);
            spriteBatch.End();

            base.Draw(gameTime);
        }
    }
}